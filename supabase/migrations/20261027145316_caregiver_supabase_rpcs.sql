-- Caregiver links are mutated only through role-checked database functions.
create unique index if not exists caregiver_links_one_pending_patient
  on public.caregiver_links (patient_id)
  where status = 'pending' and caregiver_id is null;

create unique index if not exists caregiver_links_pending_pairing_code
  on public.caregiver_links (pairing_code)
  where status = 'pending' and pairing_code is not null;

drop policy if exists caregiver_links_select on public.caregiver_links;
drop policy if exists caregiver_links_insert on public.caregiver_links;
drop policy if exists caregiver_links_update on public.caregiver_links;
drop policy if exists caregiver_links_delete on public.caregiver_links;
drop policy if exists caregiver_links_select_participant on public.caregiver_links;

create policy caregiver_links_select_participant
  on public.caregiver_links
  for select
  to authenticated
  using (
    patient_id = (select auth.uid())
    or (
      caregiver_id = (select auth.uid())
      and status::text in ('active', 'accepted')
    )
  );

revoke all on table public.caregiver_links from public, anon, authenticated;
grant select on table public.caregiver_links to authenticated;

create or replace function public.generate_caregiver_pairing_code()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_code text;
  v_expires_at timestamptz := pg_catalog.now() + interval '10 minutes';
  v_link_id uuid;
  v_attempt integer := 0;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;

  select u.role::text
    into v_actor_role
    from public.users as u
   where u.id = v_actor_id;

  if v_actor_role is distinct from 'patient' then
    raise exception using errcode = '42501', message = 'INVALID_ROLE';
  end if;

  loop
    v_attempt := v_attempt + 1;
    if v_attempt > 100 then
      raise exception using errcode = 'P0001', message = 'PAIRING_CODE_GENERATION_FAILED';
    end if;

    v_code := pg_catalog.lpad(
      (
        100000
        + (
          (
            ('x' || pg_catalog.encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint
          ) % 900000
        )
      )::text,
      6,
      '0'
    );

    begin
      select cl.id
        into v_link_id
        from public.caregiver_links as cl
       where cl.patient_id = v_actor_id
         and cl.caregiver_id is null
         and cl.status::text = 'pending'
       for update;

      if v_link_id is null then
        insert into public.caregiver_links (
          patient_id,
          pairing_code,
          pairing_code_expires_at,
          status,
          updated_at
        ) values (
          v_actor_id,
          v_code,
          v_expires_at,
          'pending',
          v_expires_at - interval '10 minutes'
        );
      else
        update public.caregiver_links as cl
           set pairing_code = v_code,
               pairing_code_expires_at = v_expires_at,
               updated_at = pg_catalog.now()
         where cl.id = v_link_id;
      end if;

      exit;
    exception when unique_violation then
      v_link_id := null;
    end;
  end loop;

  return pg_catalog.jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$function$;

create or replace function public.consume_caregiver_pairing_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_code text := pg_catalog.btrim(coalesce(p_code, ''));
  v_now timestamptz := pg_catalog.now();
  v_link_id uuid;
  v_patient_id uuid;
  v_existing_link_id uuid;
  v_existing_status text;
  v_patient_name text;
  v_patient_phone text;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;

  select u.role::text
    into v_actor_role
    from public.users as u
   where u.id = v_actor_id;

  if v_actor_role is distinct from 'caregiver' then
    raise exception using errcode = '42501', message = 'INVALID_ROLE';
  end if;

  if v_code !~ '^[0-9]{6}$' then
    raise exception using errcode = 'P0001', message = 'INVALID_CODE';
  end if;

  select cl.id, cl.patient_id
    into v_link_id, v_patient_id
    from public.caregiver_links as cl
    join public.users as patient on patient.id = cl.patient_id
   where cl.pairing_code = v_code
     and cl.caregiver_id is null
     and cl.status::text = 'pending'
     and cl.pairing_code_expires_at > v_now
     and patient.role::text = 'patient'
   for update of cl;

  if v_link_id is null then
    raise exception using errcode = 'P0001', message = 'INVALID_CODE';
  end if;

  if v_patient_id = v_actor_id then
    raise exception using errcode = 'P0001', message = 'CANNOT_PAIR_SELF';
  end if;

  select cl.id, cl.status::text
    into v_existing_link_id, v_existing_status
    from public.caregiver_links as cl
   where cl.caregiver_id = v_actor_id
     and cl.patient_id = v_patient_id
   for update;

  if v_existing_status in ('active', 'accepted') then
    raise exception using errcode = 'P0001', message = 'ALREADY_LINKED';
  end if;

  if v_existing_link_id is not null and v_existing_status = 'revoked' then
    update public.caregiver_links as cl
       set status = 'revoked',
           pairing_code = null,
           pairing_code_expires_at = null,
           updated_at = v_now
     where cl.id = v_link_id;

    update public.caregiver_links as cl
       set status = 'active',
           linked_at = v_now,
           updated_at = v_now
     where cl.id = v_existing_link_id;
  elsif v_existing_link_id is not null then
    raise exception using errcode = 'P0001', message = 'PAIRING_ALREADY_PENDING';
  else
    update public.caregiver_links as cl
       set caregiver_id = v_actor_id,
           status = 'active',
           linked_at = v_now,
           pairing_code = null,
           pairing_code_expires_at = null,
           updated_at = v_now
     where cl.id = v_link_id;
  end if;

  select u.name, u.phone
    into v_patient_name, v_patient_phone
    from public.users as u
   where u.id = v_patient_id;

  return pg_catalog.jsonb_build_object(
    'patient_id', v_patient_id,
    'name', v_patient_name,
    'phone', v_patient_phone,
    'status', 'active',
    'linked_at', v_now
  );
end;
$function$;

create or replace function public.list_patient_caregivers(p_patient_id uuid)
returns table (
  caregiver_id uuid,
  name text,
  phone text,
  status text,
  linked_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_can_access boolean := false;
begin
  if v_actor_id is null or p_patient_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;

  select u.role::text
    into v_actor_role
    from public.users as u
   where u.id = v_actor_id;

  if v_actor_role = 'patient' then
    v_can_access := (p_patient_id = v_actor_id);
  elsif v_actor_role = 'caregiver' then
    select exists (
      select 1
        from public.caregiver_links as cl
       where cl.caregiver_id = v_actor_id
         and cl.patient_id = p_patient_id
         and cl.status::text in ('active', 'accepted')
    ) into v_can_access;
  elsif v_actor_role = 'admin' then
    v_can_access := true;
  end if;

  if not v_can_access then
    raise exception using errcode = '42501', message = 'FORBIDDEN';
  end if;

  return query
  select cl.caregiver_id,
         u.name::text,
         u.phone::text,
         cl.status::text,
         cl.linked_at
    from public.caregiver_links as cl
    join public.users as u on u.id = cl.caregiver_id
   where cl.patient_id = p_patient_id
     and cl.status::text in ('active', 'accepted')
   order by cl.linked_at nulls last, cl.caregiver_id;
end;
$function$;

create or replace function public.get_caregiver_dashboard(p_now timestamptz default null)
returns table (
  patient_id uuid,
  name text,
  phone text,
  status text,
  linked_at timestamptz,
  today_taken_count integer,
  today_missed_count integer,
  active_alerts_count integer,
  missed_doses jsonb
)
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_now timestamptz := coalesce(p_now, pg_catalog.now());
  v_day_start timestamptz;
  v_day_end timestamptz;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;

  select u.role::text
    into v_actor_role
    from public.users as u
   where u.id = v_actor_id;

  if v_actor_role is distinct from 'caregiver' then
    raise exception using errcode = '42501', message = 'INVALID_ROLE';
  end if;

  v_day_start := ((v_now at time zone 'UTC')::date)::timestamp at time zone 'UTC';
  v_day_end := v_day_start + interval '1 day';

  return query
  with linked as materialized (
    select cl.patient_id,
           cl.status::text as link_status,
           cl.linked_at,
           u.name::text as patient_name,
           u.phone::text as patient_phone
      from public.caregiver_links as cl
      join public.users as u on u.id = cl.patient_id
     where cl.caregiver_id = v_actor_id
       and cl.status::text in ('active', 'accepted')
  ), doses as (
    select l.patient_id,
           m.id as medication_id,
           m.name::text as medication_name,
           s.id as schedule_id,
           s.time_of_day,
           ((v_now at time zone 'UTC')::date + s.time_of_day) at time zone 'UTC' as scheduled_at
      from linked as l
      join public.medications as m
        on m.patient_id = l.patient_id
       and m.is_active
      join public.schedules as s
        on s.medication_id = m.id
       and s.is_active
  ), latest_logs as (
    select distinct on (i.schedule_id)
           i.patient_id,
           i.schedule_id,
           i.status::text as log_status
      from public.intake_logs as i
      join linked as l on l.patient_id = i.patient_id
     where i.scheduled_time >= v_day_start
       and i.scheduled_time < v_day_end
     order by i.schedule_id, i.scheduled_time desc, i.created_at desc
  ), dose_state as (
    select d.*,
           coalesce(ll.log_status = 'taken', false) as is_taken,
           (
             coalesce(ll.log_status = 'missed', false)
             or (
               ll.log_status is null
               and v_now >= d.scheduled_at + interval '15 minutes'
             )
           ) as is_missed
      from doses as d
      left join latest_logs as ll
        on ll.patient_id = d.patient_id
       and ll.schedule_id = d.schedule_id
  )
  select l.patient_id,
         l.patient_name,
         l.patient_phone,
         l.link_status,
         l.linked_at,
         pg_catalog.count(d.schedule_id) filter (where d.is_taken)::integer,
         pg_catalog.count(d.schedule_id) filter (where d.is_missed)::integer,
         pg_catalog.count(d.schedule_id) filter (where d.is_missed)::integer,
         coalesce(
           pg_catalog.jsonb_agg(
             pg_catalog.jsonb_build_object(
               'schedule_id', d.schedule_id,
               'medication_id', d.medication_id,
               'medication_name', d.medication_name,
               'time_of_day', pg_catalog.to_char(d.time_of_day, 'HH24:MI'),
               'scheduled_time', d.scheduled_at
             ) order by d.scheduled_at, d.schedule_id
           ) filter (where d.is_missed),
           '[]'::jsonb
         )
    from linked as l
    left join dose_state as d on d.patient_id = l.patient_id
   group by l.patient_id, l.patient_name, l.patient_phone, l.link_status, l.linked_at
   order by l.patient_name nulls last, l.patient_id;
end;
$function$;

revoke all on function public.generate_caregiver_pairing_code() from public, anon, authenticated;
revoke all on function public.consume_caregiver_pairing_code(text) from public, anon, authenticated;
revoke all on function public.list_patient_caregivers(uuid) from public, anon, authenticated;
revoke all on function public.get_caregiver_dashboard(timestamptz) from public, anon, authenticated;

grant execute on function public.generate_caregiver_pairing_code() to authenticated;
grant execute on function public.consume_caregiver_pairing_code(text) to authenticated;
grant execute on function public.list_patient_caregivers(uuid) to authenticated;
grant execute on function public.get_caregiver_dashboard(timestamptz) to authenticated;
