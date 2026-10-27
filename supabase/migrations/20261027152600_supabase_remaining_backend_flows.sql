-- Keep alert writes behind narrowly scoped database operations.
drop policy if exists alerts_insert on public.alerts;
drop policy if exists alerts_update on public.alerts;
drop policy if exists alerts_delete on public.alerts;
revoke all on table public.alerts from public, anon, authenticated;
grant select on table public.alerts to authenticated;

-- Device tokens and report share tokens are only changed through functions.
revoke all on table public.devices from public, anon, authenticated;
revoke all on table public.report_shares from public, anon, authenticated;

-- Contacts remain directly accessible through their patient/caregiver RLS rules.
revoke all on table public.emergency_contacts from public, anon, authenticated;
grant select, insert, update, delete on table public.emergency_contacts to authenticated;

create or replace function public.trigger_sos(
  p_lat double precision default null,
  p_lng double precision default null,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_patient_id uuid := auth.uid();
  v_role text;
  v_name text;
  v_phone text;
  v_alert_id uuid;
  v_notified_count integer;
begin
  if v_patient_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;
  if p_lat is not null and (p_lat < -90 or p_lat > 90) then
    raise exception using errcode = '22023', message = 'INVALID_LATITUDE';
  end if;
  if p_lng is not null and (p_lng < -180 or p_lng > 180) then
    raise exception using errcode = '22023', message = 'INVALID_LONGITUDE';
  end if;
  if p_note is not null and pg_catalog.length(p_note) > 500 then
    raise exception using errcode = '22023', message = 'NOTE_TOO_LONG';
  end if;

  select u.role::text, u.name, u.phone
    into v_role, v_name, v_phone
    from public.users as u
   where u.id = v_patient_id;
  if v_role is distinct from 'patient' then
    raise exception using errcode = '42501', message = 'INVALID_ROLE';
  end if;

  select
    (select pg_catalog.count(*) from public.emergency_contacts as ec where ec.patient_id = v_patient_id)
    + (select pg_catalog.count(*) from public.caregiver_links as cl
        where cl.patient_id = v_patient_id and cl.status::text in ('active', 'accepted'))
    into v_notified_count;

  insert into public.alerts (patient_id, type, tier, payload_json, sent_at)
  values (
    v_patient_id,
    'sos',
    3,
    pg_catalog.jsonb_build_object(
      'lat', p_lat,
      'lng', p_lng,
      'note', p_note,
      'patient_name', v_name,
      'patient_phone', v_phone
    )::text,
    pg_catalog.now()
  )
  returning id into v_alert_id;

  return pg_catalog.jsonb_build_object(
    'status', 'active',
    'alert_id', v_alert_id,
    'notified_contacts_count', v_notified_count
  );
end;
$function$;

revoke all on function public.trigger_sos(double precision, double precision, text) from public, anon;
grant execute on function public.trigger_sos(double precision, double precision, text) to authenticated;

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

  select coalesce(u.timezone, 'Africa/Cairo') into v_timezone
    from public.users as u where u.id = p_patient_id;
  if v_timezone is null then
    raise exception using errcode = 'P0002', message = 'PATIENT_NOT_FOUND';
  end if;
  v_local_date := v_now at time zone v_timezone;
  v_day_start := v_local_date::timestamp at time zone v_timezone;
  v_day_end := (v_local_date + 1)::timestamp at time zone v_timezone;

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
         and (s.days_mask & (1 << (extract(isodow from v_local_date)::integer - 1))) <> 0
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

revoke all on function public.list_patient_alerts(uuid, integer, timestamptz) from public, anon;
grant execute on function public.list_patient_alerts(uuid, integer, timestamptz) to authenticated;

create or replace function public.register_device(
  p_fcm_token text,
  p_platform text default 'android',
  p_app_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
  end if;
  if p_fcm_token is null or pg_catalog.length(pg_catalog.btrim(p_fcm_token)) < 20
     or pg_catalog.length(p_fcm_token) > 4096 then
    raise exception using errcode = '22023', message = 'INVALID_DEVICE_TOKEN';
  end if;
  if pg_catalog.lower(coalesce(p_platform, '')) not in ('android', 'ios', 'web') then
    raise exception using errcode = '22023', message = 'INVALID_DEVICE_PLATFORM';
  end if;

  insert into public.devices (user_id, fcm_token, platform, app_version, last_seen)
  values (v_user_id, p_fcm_token, pg_catalog.lower(p_platform), p_app_version, pg_catalog.now())
  on conflict (fcm_token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        app_version = excluded.app_version,
        last_seen = excluded.last_seen;

  return pg_catalog.jsonb_build_object('status', 'success');
end;
$function$;

revoke all on function public.register_device(text, text, text) from public, anon;
grant execute on function public.register_device(text, text, text) to authenticated;

create or replace function public.create_report_share(
  p_patient_id uuid,
  p_expires_in_hours integer default 48,
  p_scope text default 'full'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_token text;
  v_expires_at timestamptz;
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
  if p_expires_in_hours < 1 or p_expires_in_hours > 720 then
    raise exception using errcode = '22023', message = 'INVALID_EXPIRY';
  end if;
  if p_scope not in ('full', 'summary_30d') then
    raise exception using errcode = '22023', message = 'INVALID_SCOPE';
  end if;

  v_token := pg_catalog.rtrim(
    pg_catalog.translate(pg_catalog.encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'),
    '='
  );
  v_expires_at := pg_catalog.now() + pg_catalog.make_interval(hours => p_expires_in_hours);

  insert into public.report_shares (patient_id, token_hash, scope, expires_at, views_count, revoked)
  values (
    p_patient_id,
    pg_catalog.encode(extensions.digest(pg_catalog.convert_to(v_token, 'UTF8'), 'sha256'), 'hex'),
    p_scope,
    v_expires_at,
    0,
    false
  );

  return pg_catalog.jsonb_build_object('token', v_token, 'expires_at', v_expires_at);
end;
$function$;

revoke all on function public.create_report_share(uuid, integer, text) from public, anon;
grant execute on function public.create_report_share(uuid, integer, text) to authenticated;

create or replace function public.get_public_report(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_share public.report_shares%rowtype;
  v_patient public.users%rowtype;
  v_now timestamptz := pg_catalog.now();
  v_total integer;
  v_taken integer;
  v_missed integer;
  v_medications jsonb;
  v_vitals jsonb;
  v_logs jsonb;
begin
  if p_token is null or pg_catalog.length(p_token) < 40 or pg_catalog.length(p_token) > 100 then
    raise exception using errcode = 'P0002', message = 'REPORT_EXPIRED';
  end if;

  select * into v_share
    from public.report_shares as rs
   where rs.token_hash = pg_catalog.encode(
     extensions.digest(pg_catalog.convert_to(p_token, 'UTF8'), 'sha256'), 'hex'
   )
     and not rs.revoked
     and rs.expires_at > v_now
   for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'REPORT_EXPIRED';
  end if;

  update public.report_shares set views_count = views_count + 1, updated_at = v_now where id = v_share.id;

  select * into v_patient from public.users as u where u.id = v_share.patient_id;
  if not found then
    raise exception using errcode = 'P0002', message = 'PATIENT_NOT_FOUND';
  end if;

  select pg_catalog.count(*)::integer,
         pg_catalog.count(*) filter (where i.status::text = 'taken')::integer,
         pg_catalog.count(*) filter (where i.status::text = 'missed')::integer
    into v_total, v_taken, v_missed
    from public.intake_logs as i
   where i.patient_id = v_patient.id
     and i.scheduled_time >= v_now - interval '30 days';

  select coalesce(pg_catalog.jsonb_agg(medication order by medication->>'name'), '[]'::jsonb)
    into v_medications
    from (
      select pg_catalog.jsonb_build_object(
        'name', m.name,
        'dose_form', m.form,
        'strength', m.strength,
        'stock_count', m.stock_count,
        'times', coalesce((
          select pg_catalog.jsonb_agg(pg_catalog.to_char(s.time_of_day, 'HH24:MI') order by s.time_of_day)
            from public.schedules as s
           where s.medication_id = m.id and s.is_active
        ), '[]'::jsonb)
      ) as medication
      from public.medications as m
      where m.patient_id = v_patient.id and m.is_active
    ) as meds;

  select coalesce(pg_catalog.jsonb_agg(vital order by recorded_at desc), '[]'::jsonb)
    into v_vitals
    from (
      select pg_catalog.jsonb_build_object(
        'type', v.type,
        'value_primary', v.value_primary,
        'value_secondary', v.value_secondary,
        'meal_context', v.meal_context,
        'band', v.band,
        'recorded_at', v.recorded_at
      ) as vital,
      v.recorded_at
      from public.vitals_logs as v
      where v.patient_id = v_patient.id
      order by v.recorded_at desc
      limit 20
    ) as recent_vitals;

  select coalesce(pg_catalog.jsonb_agg(log_row order by scheduled_time desc), '[]'::jsonb)
    into v_logs
    from (
      select pg_catalog.jsonb_build_object(
        'scheduled_time', i.scheduled_time,
        'actual_time', i.actual_time,
        'status', i.status,
        'reason', i.reason
      ) as log_row,
      i.scheduled_time
      from public.intake_logs as i
      where i.patient_id = v_patient.id
        and i.scheduled_time >= v_now - interval '30 days'
      order by i.scheduled_time desc
      limit 20
    ) as recent_logs;

  return pg_catalog.jsonb_build_object(
    'patient_name', coalesce(nullif(v_patient.name, ''), 'مريض Medliva'),
    'patient_phone', v_patient.phone,
    'adherence_rate_pct', case when v_total > 0 then round((v_taken::numeric / v_total::numeric) * 100, 1) else 100.0 end,
    'total_doses', v_total,
    'taken_doses', v_taken,
    'missed_doses_count', v_missed,
    'active_medications', v_medications,
    'recent_vitals', v_vitals,
    'recent_intake_logs', v_logs
  );
end;
$function$;

revoke all on function public.get_public_report(text) from public, anon, authenticated;
grant execute on function public.get_public_report(text) to service_role;
