-- Create a medication and all of its initial schedules atomically under RLS.
create or replace function public.create_medication_with_schedules(
  p_patient_id uuid,
  p_medication jsonb,
  p_schedules jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_medication public.medications%rowtype;
  v_schedule jsonb;
  v_result jsonb;
  v_meal_relation text;
  v_dose_amount double precision;
  v_days_mask integer;
begin
  if p_patient_id is null or pg_catalog.jsonb_typeof(p_medication) <> 'object' then
    raise exception 'A patient and medication object are required'
      using errcode = '22023';
  end if;

  if p_schedules is not null and pg_catalog.jsonb_typeof(p_schedules) <> 'array' then
    raise exception 'Schedules must be an array' using errcode = '22023';
  end if;

  if nullif(p_medication ->> 'name', '') is null then
    raise exception 'Medication name is required' using errcode = '22023';
  end if;

  insert into public.medications (
    patient_id,
    name,
    trade_name,
    active_ingredient,
    form,
    strength,
    stock_count,
    alert_threshold_days,
    expiry_date,
    is_active
  ) values (
    p_patient_id,
    p_medication ->> 'name',
    p_medication ->> 'trade_name',
    p_medication ->> 'active_ingredient',
    coalesce(p_medication ->> 'form', 'قرص'),
    p_medication ->> 'strength',
    coalesce((p_medication ->> 'stock_count')::integer, 0),
    coalesce((p_medication ->> 'alert_threshold_days')::integer, 5),
    (p_medication ->> 'expiry_date')::date,
    true
  ) returning * into v_medication;

  for v_schedule in
    select value
    from pg_catalog.jsonb_array_elements(coalesce(p_schedules, '[]'::jsonb)) as schedules(value)
  loop
    v_meal_relation := coalesce(v_schedule ->> 'meal_relation', 'after_meal');
    if v_meal_relation not in ('before_meal', 'after_meal', 'with_meal', 'independent') then
      raise exception 'Unsupported meal relation: %', v_meal_relation
        using errcode = '22023';
    end if;

    v_dose_amount := coalesce((v_schedule ->> 'dose_amount')::double precision, 1.0);
    if v_dose_amount <= 0 then
      raise exception 'Dose amount must be greater than zero' using errcode = '22023';
    end if;

    v_days_mask := coalesce((v_schedule ->> 'days_mask')::integer, 127);
    if v_days_mask < 0 or v_days_mask > 127 then
      raise exception 'Days mask must be between 0 and 127' using errcode = '22023';
    end if;

    insert into public.schedules (
      medication_id,
      time_of_day,
      dose_amount,
      meal_relation,
      days_mask,
      instructions_ar,
      is_active
    ) values (
      v_medication.id,
      (v_schedule ->> 'time_of_day')::time,
      v_dose_amount,
      v_meal_relation,
      v_days_mask,
      v_schedule ->> 'instructions_ar',
      true
    );
  end loop;

  select pg_catalog.to_jsonb(m) || pg_catalog.jsonb_build_object(
    'schedules', coalesce((
      select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(s) order by s.time_of_day)
      from public.schedules as s
      where s.medication_id = m.id
    ), '[]'::jsonb)
  )
  into v_result
  from public.medications as m
  where m.id = v_medication.id;

  return v_result;
end;
$$;

revoke all on function public.create_medication_with_schedules(uuid, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_medication_with_schedules(uuid, jsonb, jsonb)
  to authenticated;

-- Record a dose idempotently and update stock/low-stock alerts in the same transaction.
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
security invoker
set search_path = ''
as $$
declare
  v_schedule public.schedules%rowtype;
  v_medication public.medications%rowtype;
  v_intake_log public.intake_logs%rowtype;
  v_actual_time timestamptz;
  v_new_stock integer;
  v_inserted boolean;
begin
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
    where client_uuid = p_client_uuid;
    if not found then
      raise exception 'This client UUID is already used by another account'
        using errcode = '23505';
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

    if v_new_stock <= v_medication.alert_threshold_days then
      insert into public.alerts (patient_id, type, tier, payload_json)
      values (
        v_medication.patient_id,
        'low_stock',
        1,
        pg_catalog.jsonb_build_object(
          'medication_id', v_medication.id,
          'name', v_medication.name,
          'stock_count', v_new_stock
        )::text
      );
    end if;
  end if;

  return pg_catalog.to_jsonb(v_intake_log);
end;
$$;

revoke all on function public.record_intake_log(text, uuid, timestamptz, timestamptz, text, text, boolean)
  from public, anon, authenticated;
grant execute on function public.record_intake_log(text, uuid, timestamptz, timestamptz, text, text, boolean)
  to authenticated;
