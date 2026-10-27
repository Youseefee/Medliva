alter table public.vitals_logs
  alter column id set default pg_catalog.gen_random_uuid();

-- Alert table writes are now revoked from clients. Keep vital triage and the
-- resulting critical alert atomic while checking patient/caregiver access here.
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
    elsif v_context in ('post_prandial', 'فاطر', 'بعد_الاكل') then
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

  insert into public.vitals_logs (
    client_uuid, patient_id, type, value_primary, value_secondary,
    meal_context, band
  ) values (
    p_client_uuid, p_patient_id, p_type, p_value_primary,
    p_value_secondary, p_meal_context, v_band
  ) returning * into v_vital;

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

revoke all on function public.record_vital(uuid, text, text, double precision, double precision, text) from public, anon;
grant execute on function public.record_vital(uuid, text, text, double precision, double precision, text) to authenticated;
