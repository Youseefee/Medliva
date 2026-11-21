-- Migration: 20261028143000_backend_schema_integrity_and_triggers.sql
-- Fix schema defaults, missing triggers, RLS and RPC security permissions.

-- 1. Ensure table IDs have database default UUID generation
alter table public.intake_logs
  alter column id set default pg_catalog.gen_random_uuid();

alter table public.prescriptions
  alter column id set default pg_catalog.gen_random_uuid();

alter table public.caregiver_links
  alter column id set default pg_catalog.gen_random_uuid();

alter table public.drug_catalog
  alter column id set default pg_catalog.gen_random_uuid();

-- 2. Fix emergency_contacts defaults for client inserts
alter table public.emergency_contacts
  alter column notify_call set default true,
  alter column is_primary set default false;

-- 3. Fix caregiver_links status and permissions defaults
alter table public.caregiver_links
  alter column status set default 'pending',
  alter column permissions_mask set default 255;

-- 4. Fix devices fcm_token length capacity
alter table public.devices
  alter column fcm_token type varchar(4096);

-- 5. Create auth.users trigger for public.handle_new_user()
-- This ensures user registration via Supabase Auth creates the public.users profile row.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_name text;
  v_lang text;
begin
  v_role := pg_catalog.lower(coalesce(new.raw_user_meta_data ->> 'role', 'patient'));
  if v_role not in ('patient', 'caregiver') then
    v_role := 'patient';
  end if;

  v_name := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name',
    ''
  );
  v_lang := pg_catalog.lower(coalesce(new.raw_user_meta_data ->> 'language', 'ar'));
  if v_lang not in ('ar', 'en') then
    v_lang := 'ar';
  end if;

  insert into public.users (
    id,
    email,
    phone,
    name,
    role,
    language,
    timezone,
    created_at,
    updated_at
  ) values (
    new.id,
    nullif(new.email, ''),
    nullif(new.phone, ''),
    v_name,
    v_role,
    v_lang,
    'Africa/Cairo',
    pg_catalog.now(),
    pg_catalog.now()
  )
  on conflict (id) do update set
    email = coalesce(nullif(excluded.email, ''), users.email),
    phone = coalesce(nullif(excluded.phone, ''), users.phone),
    updated_at = pg_catalog.now();

  return new;
end;
$$;

grant execute on function public.handle_new_user() to postgres, service_role;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant execute on function public.handle_new_user() to supabase_auth_admin;
  end if;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 6. Re-define record_intake_log as security definer
-- Since alert table writes are revoked from authenticated users,
-- recording a dose that triggers a low-stock alert must be security definer
-- with explicit actor authorization checks.
create or replace function public.record_intake_log(
  p_client_uuid text,
  p_schedule_id uuid,
  p_scheduled_time timestamptz,
  p_actual_time timestamptz,
  p_status text,
  p_reason text,
  p_logged_offline boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_schedule public.schedules%rowtype;
  v_medication public.medications%rowtype;
  v_intake_log public.intake_logs%rowtype;
  v_actual_time timestamptz;
  v_new_stock integer;
  v_daily_dose double precision;
  v_days_remaining integer;
  v_inserted boolean;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;

  if p_client_uuid is null or p_client_uuid = '' or p_schedule_id is null or p_scheduled_time is null then
    raise exception 'Client UUID, schedule, and scheduled time are required'
      using errcode = '22023';
  end if;

  if p_status is null or p_status not in ('taken', 'snoozed', 'missed', 'skipped') then
    raise exception 'Unsupported intake status: %', p_status using errcode = '22023';
  end if;

  select * into v_schedule
  from public.schedules
  where id = p_schedule_id;

  if not found then
    raise exception 'Schedule not found' using errcode = 'P0002';
  end if;

  select * into v_medication
  from public.medications
  where id = v_schedule.medication_id;

  if not found then
    raise exception 'Medication not found' using errcode = 'P0002';
  end if;

  -- Caller must be the patient or an active caregiver
  if v_medication.patient_id <> v_actor_id and not exists (
    select 1 from public.caregiver_links as cl
    where cl.caregiver_id = v_actor_id
      and cl.patient_id = v_medication.patient_id
      and cl.status::text in ('active', 'accepted')
  ) then
    raise exception using errcode = '42501', message = 'PATIENT_ACCESS_DENIED';
  end if;

  v_actual_time := coalesce(
    p_actual_time,
    case when p_status = 'taken' then pg_catalog.now() else null end
  );

  insert into public.intake_logs (
    client_uuid,
    schedule_id,
    patient_id,
    scheduled_time,
    actual_time,
    status,
    reason,
    logged_offline
  ) values (
    p_client_uuid,
    v_schedule.id,
    v_medication.patient_id,
    p_scheduled_time,
    v_actual_time,
    p_status,
    p_reason,
    coalesce(p_logged_offline, false)
  )
  on conflict (client_uuid) do nothing
  returning * into v_intake_log;

  v_inserted := found;
  if not v_inserted then
    select * into v_intake_log
    from public.intake_logs
    where client_uuid = p_client_uuid
      and patient_id = v_medication.patient_id;
    if not found then
      raise exception 'CLIENT_UUID_CONFLICT'
        using errcode = '23505', detail = 'This client UUID is already used by another account';
    end if;
    return pg_catalog.to_jsonb(v_intake_log);
  end if;

  if p_status = 'taken' then
    update public.medications
    set stock_count = greatest(
      0,
      pg_catalog.trunc(stock_count - v_schedule.dose_amount)::integer
    ),
        updated_at = pg_catalog.now()
    where id = v_medication.id
    returning stock_count into v_new_stock;

    if not found then
      raise exception 'Medication is not accessible to this user' using errcode = '42501';
    end if;

    -- Compute effective daily dose weighted by each active schedule's days_mask.
    select coalesce(
      pg_catalog.sum(
        s.dose_amount * (
          (
            ((coalesce(s.days_mask, 127) & 1) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 2) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 4) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 8) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 16) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 32) <> 0)::integer
            + ((coalesce(s.days_mask, 127) & 64) <> 0)::integer
          )::double precision / 7.0
        )
      ),
      0.0
    )
    into v_daily_dose
    from public.schedules as s
    where s.medication_id = v_medication.id
      and s.is_active;

    if v_daily_dose > 0 then
      v_days_remaining := pg_catalog.floor(v_new_stock::double precision / v_daily_dose)::integer;
    else
      v_days_remaining := v_new_stock;
    end if;

    if v_days_remaining <= v_medication.alert_threshold_days then
      if not exists (
        select 1
        from public.alerts as a
        where a.patient_id = v_medication.patient_id
          and a.type = 'low_stock'
          and a.acknowledged_at is null
          and a.payload_json is not null
          and (a.payload_json::jsonb ->> 'medication_id') = v_medication.id::text
      ) then
        insert into public.alerts (patient_id, type, tier, payload_json)
        values (
          v_medication.patient_id,
          'low_stock',
          1,
          pg_catalog.jsonb_build_object(
            'medication_id', v_medication.id,
            'medication_name', v_medication.name,
            'name', v_medication.name,
            'stock_count', v_new_stock,
            'days_remaining', v_days_remaining
          )::text
        );
      end if;
    end if;
  end if;

  return pg_catalog.to_jsonb(v_intake_log);
end;
$$;

revoke all on function public.record_intake_log(text, uuid, timestamptz, timestamptz, text, text, boolean)
  from public, anon, authenticated;
grant execute on function public.record_intake_log(text, uuid, timestamptz, timestamptz, text, text, boolean)
  to authenticated;

-- 7. Update record_vital for complete Arabic context support and idempotent client UUID handling
create or replace function public.record_vital(
  p_patient_id uuid,
  p_client_uuid text,
  p_type text,
  p_value_primary double precision,
  p_value_secondary double precision,
  p_meal_context text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_band text;
  v_context text := pg_catalog.lower(coalesce(p_meal_context, 'random'));
  v_vital public.vitals_logs%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;
  if p_patient_id <> v_actor_id and not exists (
    select 1 from public.caregiver_links as cl
     where cl.caregiver_id = v_actor_id
       and cl.patient_id = p_patient_id
       and cl.status::text in ('active', 'accepted')
  ) then
    raise exception using errcode = '42501', message = 'PATIENT_ACCESS_DENIED';
  end if;
  if p_type is null or p_type not in ('bp', 'glucose', 'pulse') then
    raise exception using errcode = '22023', message = 'UNSUPPORTED_VITAL_TYPE';
  end if;

  if p_type = 'bp' then
    if p_value_primary >= 180
       or p_value_primary <= 90
       or (case when p_value_secondary is null or p_value_secondary = 0 then 80 else p_value_secondary end) >= 120
       or (case when p_value_secondary is null or p_value_secondary = 0 then 80 else p_value_secondary end) <= 50 then
      v_band := 'critical';
    elsif p_value_primary >= 130
       or (case when p_value_secondary is null or p_value_secondary = 0 then 80 else p_value_secondary end) > 80 then
      v_band := 'borderline';
    else
      v_band := 'normal';
    end if;
  elsif p_type = 'glucose' then
    if v_context in ('fasting', 'صايم', 'صائم') then
      if p_value_primary < 70 or p_value_primary > 250 then
        v_band := 'critical';
      elsif p_value_primary > 110 then
        v_band := 'borderline';
      else
        v_band := 'normal';
      end if;
    elsif v_context in ('post_prandial', 'فاطر', 'بعد_الاكل', 'بعد_الأكل') then
      if p_value_primary < 70 or p_value_primary > 300 then
        v_band := 'critical';
      elsif p_value_primary > 140 then
        v_band := 'borderline';
      else
        v_band := 'normal';
      end if;
    elsif p_value_primary < 70 or p_value_primary > 250 then
      v_band := 'critical';
    elsif p_value_primary > 140 then
      v_band := 'borderline';
    else
      v_band := 'normal';
    end if;
  else
    if p_value_primary < 50 or p_value_primary > 120 then
      v_band := 'critical';
    elsif p_value_primary < 60 or p_value_primary > 100 then
      v_band := 'borderline';
    else
      v_band := 'normal';
    end if;
  end if;

  if p_client_uuid is not null and p_client_uuid <> '' then
    insert into public.vitals_logs (
      client_uuid, patient_id, type, value_primary, value_secondary,
      meal_context, band
    ) values (
      p_client_uuid, p_patient_id, p_type, p_value_primary,
      p_value_secondary, p_meal_context, v_band
    )
    on conflict (client_uuid) do nothing
    returning * into v_vital;

    if not found then
      select * into v_vital
      from public.vitals_logs
      where client_uuid = p_client_uuid
        and patient_id = p_patient_id;
      if not found then
        raise exception 'CLIENT_UUID_CONFLICT'
          using errcode = '23505', detail = 'This client UUID is already used by another account';
      end if;
      return pg_catalog.to_jsonb(v_vital);
    end if;
  else
    insert into public.vitals_logs (
      client_uuid, patient_id, type, value_primary, value_secondary,
      meal_context, band
    ) values (
      null, p_patient_id, p_type, p_value_primary,
      p_value_secondary, p_meal_context, v_band
    ) returning * into v_vital;
  end if;

  if v_band = 'critical' then
    insert into public.alerts (patient_id, type, tier, payload_json)
    values (
      p_patient_id,
      'critical_vital',
      2,
      pg_catalog.jsonb_build_object(
        'type', p_type,
        'value_primary', p_value_primary,
        'value_secondary', p_value_secondary
      )::text
    );
  end if;

  return pg_catalog.to_jsonb(v_vital);
end;
$function$;

revoke all on function public.record_vital(uuid, text, text, double precision, double precision, text) from public, anon, authenticated;
grant execute on function public.record_vital(uuid, text, text, double precision, double precision, text) to authenticated;

-- 8. Align days_mask (Sat=bit0..Fri=bit6), patient timezone, and unacknowledged alerts in get_caregiver_dashboard
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

  return query
  with linked as materialized (
    select cl.patient_id,
           cl.status::text as link_status,
           cl.linked_at,
           u.name::text as patient_name,
           u.phone::text as patient_phone,
           coalesce(nullif(u.timezone, ''), 'Africa/Cairo') as patient_timezone,
           (v_now at time zone coalesce(nullif(u.timezone, ''), 'Africa/Cairo'))::date as local_date
      from public.caregiver_links as cl
      join public.users as u on u.id = cl.patient_id
     where cl.caregiver_id = v_actor_id
       and cl.status::text in ('active', 'accepted')
  ), linked_bounds as materialized (
    select l.*,
           (l.local_date::timestamp at time zone l.patient_timezone) as day_start,
           ((l.local_date + 1)::timestamp at time zone l.patient_timezone) as day_end,
           (1 << ((extract(dow from l.local_date)::integer + 1) % 7)) as today_day_bit
      from linked as l
  ), doses as (
    select l.patient_id,
           m.id as medication_id,
           m.name::text as medication_name,
           s.id as schedule_id,
           s.time_of_day,
           ((l.local_date + s.time_of_day) at time zone l.patient_timezone) as scheduled_at
      from linked_bounds as l
      join public.medications as m
        on m.patient_id = l.patient_id
       and m.is_active
      join public.schedules as s
        on s.medication_id = m.id
       and s.is_active
     where (s.days_mask is null or (s.days_mask & l.today_day_bit) <> 0)
       and (s.start_date is null or s.start_date <= l.local_date)
       and (s.end_date is null or s.end_date >= l.local_date)
  ), latest_logs as (
    select distinct on (i.schedule_id)
           i.patient_id,
           i.schedule_id,
           i.status::text as log_status
      from public.intake_logs as i
      join linked_bounds as l on l.patient_id = i.patient_id
     where i.scheduled_time >= l.day_start
       and i.scheduled_time < l.day_end
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
  ), unack_alerts as (
    select a.patient_id,
           pg_catalog.count(*)::integer as stored_alert_count
      from public.alerts as a
      join linked_bounds as l on l.patient_id = a.patient_id
     where a.acknowledged_at is null
       and a.type::text in ('sos', 'critical_vital', 'low_stock', 'expiry')
     group by a.patient_id
  )
  select l.patient_id,
         l.patient_name,
         l.patient_phone,
         l.link_status,
         l.linked_at,
         pg_catalog.count(d.schedule_id) filter (where d.is_taken)::integer,
         pg_catalog.count(d.schedule_id) filter (where d.is_missed)::integer,
         (
           pg_catalog.count(d.schedule_id) filter (where d.is_missed)::integer
           + coalesce(ua.stored_alert_count, 0)
         )::integer,
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
    from linked_bounds as l
    left join dose_state as d on d.patient_id = l.patient_id
    left join unack_alerts as ua on ua.patient_id = l.patient_id
   group by l.patient_id, l.patient_name, l.patient_phone, l.link_status, l.linked_at, ua.stored_alert_count
   order by l.patient_name nulls last, l.patient_id;
end;
$function$;

revoke all on function public.get_caregiver_dashboard(timestamptz) from public, anon, authenticated;
grant execute on function public.get_caregiver_dashboard(timestamptz) to authenticated;

-- 8b. Align list_patient_alerts days_mask bit order (Sat=bit0..Fri=bit6) with Flutter
create or replace function public.list_patient_alerts(
  p_patient_id uuid,
  p_limit integer default 50,
  p_now timestamptz default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_now timestamptz := coalesce(p_now, pg_catalog.now());
  v_timezone text;
  v_local_date date;
  v_day_start timestamptz;
  v_day_end timestamptz;
  v_today_day_bit integer;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;
  if p_limit < 1 or p_limit > 200 then
    raise exception using errcode = '22023', message = 'INVALID_LIMIT';
  end if;
  if p_patient_id <> v_actor_id and not exists (
    select 1 from public.caregiver_links as cl
     where cl.caregiver_id = v_actor_id
       and cl.patient_id = p_patient_id
       and cl.status::text in ('active', 'accepted')
  ) then
    raise exception using errcode = '42501', message = 'PATIENT_ACCESS_DENIED';
  end if;

  select coalesce(nullif(u.timezone, ''), 'Africa/Cairo') into v_timezone
    from public.users as u where u.id = p_patient_id;
  if not found then
    raise exception using errcode = 'P0002', message = 'PATIENT_NOT_FOUND';
  end if;

  v_local_date := (v_now at time zone v_timezone)::date;
  v_day_start := v_local_date::timestamp at time zone v_timezone;
  v_day_end := (v_local_date + 1)::timestamp at time zone v_timezone;
  v_today_day_bit := 1 << ((extract(dow from v_local_date)::integer + 1) % 7);

  return (
    with stored as (
      select
        pg_catalog.jsonb_build_object(
          'id', a.id::text,
          'patient_id', a.patient_id::text,
          'type', a.type,
          'tier', a.tier,
          'payload', case when a.payload_json is null then '{}'::jsonb else a.payload_json::jsonb end,
          'sent_at', a.sent_at,
          'acknowledged_at', a.acknowledged_at,
          'created_at', a.created_at
        ) as item,
        a.created_at as event_at,
        a.id::text as event_id
      from public.alerts as a
      where a.patient_id = p_patient_id
    ), doses as (
      select m.id as medication_id,
             m.name as medication_name,
             s.id as schedule_id,
             s.time_of_day,
             ((v_local_date + s.time_of_day) at time zone v_timezone) as scheduled_at
        from public.medications as m
        join public.schedules as s on s.medication_id = m.id
       where m.patient_id = p_patient_id
         and m.is_active
         and s.is_active
         and (s.days_mask is null or (s.days_mask & v_today_day_bit) <> 0)
         and (s.start_date is null or s.start_date <= v_local_date)
         and (s.end_date is null or s.end_date >= v_local_date)
    ), dose_state as (
      select d.*,
             latest.status::text as latest_status
        from doses as d
        left join lateral (
          select i.status
            from public.intake_logs as i
           where i.patient_id = p_patient_id
             and i.schedule_id = d.schedule_id
             and i.scheduled_time >= v_day_start
             and i.scheduled_time < v_day_end
           order by i.scheduled_time desc, i.created_at desc
           limit 1
        ) as latest on true
    ), derived as (
      select
        pg_catalog.jsonb_build_object(
          'id', 'missed-dose:' || d.schedule_id::text || ':' || v_local_date::text,
          'patient_id', p_patient_id::text,
          'type', 'missed_dose',
          'tier', 1,
          'payload', pg_catalog.jsonb_build_object(
            'schedule_id', d.schedule_id,
            'medication_id', d.medication_id,
            'medication_name', d.medication_name,
            'time_of_day', pg_catalog.to_char(d.time_of_day, 'HH24:MI'),
            'scheduled_time', d.scheduled_at
          ),
          'sent_at', d.scheduled_at + interval '15 minutes',
          'acknowledged_at', null,
          'created_at', d.scheduled_at + interval '15 minutes'
        ) as item,
        d.scheduled_at + interval '15 minutes' as event_at,
        ('missed-dose:' || d.schedule_id::text) as event_id
      from dose_state as d
      where d.latest_status = 'missed'
         or (d.latest_status is null and v_now >= d.scheduled_at + interval '15 minutes')
    ), all_alerts as (
      select * from stored
      union all
      select * from derived
    )
    select coalesce(
      pg_catalog.jsonb_agg(item order by event_at desc, event_id desc),
      '[]'::jsonb
    )
      from (select item, event_at, event_id from all_alerts order by event_at desc, event_id desc limit p_limit) as recent
  );
end;
$function$;

revoke all on function public.list_patient_alerts(uuid, integer, timestamptz) from public, anon, authenticated;
grant execute on function public.list_patient_alerts(uuid, integer, timestamptz) to authenticated;

-- 9. Seed public.drug_catalog idempotently with Egyptian and common medications
insert into public.drug_catalog (id, trade_name, active_ingredient, strength, form, manufacturer, price_egp)
select pg_catalog.gen_random_uuid(), d.trade_name, d.active_ingredient, d.strength, d.form, d.manufacturer, d.price_egp
from (values
  ('Glucophage 500mg', 'Metformin', '500mg', 'قرص', 'Merck', 60.0),
  ('Glucophage 1000mg', 'Metformin', '1000mg', 'قرص', 'Merck', 90.0),
  ('Cidophage 500mg', 'Metformin', '500mg', 'قرص', 'CID', 30.0),
  ('Cidophage 850mg', 'Metformin', '850mg', 'قرص', 'CID', 40.0),
  ('Cidophage Retard 850mg', 'Metformin', '850mg', 'قرص', 'CID', 45.0),
  ('Amaryl 1mg', 'Glimepiride', '1mg', 'قرص', 'Sanofi', 42.0),
  ('Amaryl 2mg', 'Glimepiride', '2mg', 'قرص', 'Sanofi', 54.0),
  ('Amaryl 3mg', 'Glimepiride', '3mg', 'قرص', 'Sanofi', 66.0),
  ('Amaryl 4mg', 'Glimepiride', '4mg', 'قرص', 'Sanofi', 78.0),
  ('Diamicron MR 30mg', 'Gliclazide', '30mg', 'قرص', 'Servier', 55.0),
  ('Diamicron MR 60mg', 'Gliclazide', '60mg', 'قرص', 'Servier', 85.0),
  ('Januvia 50mg', 'Sitagliptin', '50mg', 'قرص', 'MSD', 180.0),
  ('Januvia 100mg', 'Sitagliptin', '100mg', 'قرص', 'MSD', 320.0),
  ('Galvus 50mg', 'Vildagliptin', '50mg', 'قرص', 'Novartis', 160.0),
  ('Galvus Met 50/1000mg', 'Vildagliptin / Metformin', '50/1000mg', 'قرص', 'Novartis', 220.0),
  ('Jardiance 10mg', 'Empagliflozin', '10mg', 'قرص', 'Boehringer Ingelheim', 350.0),
  ('Jardiance 25mg', 'Empagliflozin', '25mg', 'قرص', 'Boehringer Ingelheim', 410.0),
  ('Forxiga 10mg', 'Dapagliflozin', '10mg', 'قرص', 'AstraZeneca', 380.0),
  ('Concor 2.5mg', 'Bisoprolol fumarate', '2.5mg', 'قرص', 'Merck', 45.0),
  ('Concor 5mg', 'Bisoprolol fumarate', '5mg', 'قرص', 'Merck', 60.0),
  ('Concor 10mg', 'Bisoprolol fumarate', '10mg', 'قرص', 'Merck', 80.0),
  ('Concor Cor 2.5mg', 'Bisoprolol fumarate', '2.5mg', 'قرص', 'Merck', 48.0),
  ('Norvasc 5mg', 'Amlodipine', '5mg', 'قرص', 'Pfizer', 65.0),
  ('Norvasc 10mg', 'Amlodipine', '10mg', 'قرص', 'Pfizer', 85.0),
  ('Coversyl 5mg', 'Perindopril', '5mg', 'قرص', 'Servier', 95.0),
  ('Coversyl 10mg', 'Perindopril', '10mg', 'قرص', 'Servier', 130.0),
  ('Atacand 8mg', 'Candesartan cilexetil', '8mg', 'قرص', 'AstraZeneca', 75.0),
  ('Atacand 16mg', 'Candesartan cilexetil', '16mg', 'قرص', 'AstraZeneca', 110.0),
  ('Capoten 25mg', 'Captopril', '25mg', 'قرص', 'Bristol-Myers Squibb', 35.0),
  ('Exforge 5/160mg', 'Amlodipine / Valsartan', '5/160mg', 'قرص', 'Novartis', 190.0),
  ('Exforge 10/160mg', 'Amlodipine / Valsartan', '10/160mg', 'قرص', 'Novartis', 215.0),
  ('Lasix 40mg', 'Furosemide', '40mg', 'قرص', 'Sanofi', 25.0),
  ('Aldactone 25mg', 'Spironolactone', '25mg', 'قرص', 'Pfizer', 38.0),
  ('Aspirin Protect 100mg', 'Acetylsalicylic acid', '100mg', 'قرص', 'Bayer', 40.0),
  ('Plavix 75mg', 'Clopidogrel', '75mg', 'قرص', 'Sanofi', 220.0),
  ('Lipitor 10mg', 'Atorvastatin', '10mg', 'قرص', 'Pfizer', 110.0),
  ('Lipitor 20mg', 'Atorvastatin', '20mg', 'قرص', 'Pfizer', 160.0),
  ('Lipitor 40mg', 'Atorvastatin', '40mg', 'قرص', 'Pfizer', 210.0),
  ('Crestor 10mg', 'Rosuvastatin', '10mg', 'قرص', 'AstraZeneca', 180.0),
  ('Crestor 20mg', 'Rosuvastatin', '20mg', 'قرص', 'AstraZeneca', 260.0),
  ('Augmentin 1g', 'Amoxicillin / Clavulanate', '1g', 'قرص', 'GSK', 115.0),
  ('Augmentin 625mg', 'Amoxicillin / Clavulanate', '625mg', 'قرص', 'GSK', 85.0),
  ('Curam 1g', 'Amoxicillin / Clavulanate', '1g', 'قرص', 'Sandoz', 95.0),
  ('Ciprofar 500mg', 'Ciprofloxacin', '500mg', 'قرص', 'Pharco', 45.0),
  ('Panadol Extra', 'Paracetamol / Caffeine', '500/65mg', 'قرص', 'Haleon', 45.0),
  ('Panadol Advance', 'Paracetamol', '500mg', 'قرص', 'Haleon', 35.0),
  ('Cataflam 50mg', 'Diclofenac potassium', '50mg', 'قرص', 'Novartis', 55.0),
  ('Voltaren 75mg', 'Diclofenac sodium', '75mg', 'أمبول', 'Novartis', 60.0),
  ('Voltaren 100mg', 'Diclofenac sodium', '100mg', 'لبوس', 'Novartis', 50.0),
  ('Brufen 400mg', 'Ibuprofen', '400mg', 'قرص', 'Abbott', 40.0),
  ('Brufen 600mg', 'Ibuprofen', '600mg', 'فوار', 'Abbott', 55.0),
  ('Ketofan 50mg', 'Ketoprofen', '50mg', 'كبسول', 'Amriya', 30.0),
  ('Antinal', 'Nifuroxazide', '200mg', 'كبسول', 'Amoun', 35.0),
  ('Flagyl 500mg', 'Metronidazole', '500mg', 'قرص', 'Sanofi', 25.0),
  ('Nexium 20mg', 'Esomeprazole', '20mg', 'قرص', 'AstraZeneca', 140.0),
  ('Nexium 40mg', 'Esomeprazole', '40mg', 'قرص', 'AstraZeneca', 210.0),
  ('Controloc 20mg', 'Pantoprazole', '20mg', 'قرص', 'Takeda', 95.0),
  ('Controloc 40mg', 'Pantoprazole', '40mg', 'قرص', 'Takeda', 160.0),
  ('Eltroxin 50mcg', 'Levothyroxine sodium', '50mcg', 'قرص', 'Aspen', 70.0),
  ('Eltroxin 100mcg', 'Levothyroxine sodium', '100mcg', 'قرص', 'Aspen', 95.0),
  ('Milga Advance', 'Benfotiamine / B6 / B12', '300mg', 'قرص', 'Eva Pharma', 85.0),
  ('Neurontin 300mg', 'Gabapentin', '300mg', 'كبسول', 'Pfizer', 125.0),
  ('Lyrica 75mg', 'Pregabalin', '75mg', 'كبسول', 'Pfizer', 190.0)
) as d(trade_name, active_ingredient, strength, form, manufacturer, price_egp)
where not exists (
  select 1 from public.drug_catalog c
  where lower(c.trade_name) = lower(d.trade_name)
);

