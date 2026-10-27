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

  select u.role::text into v_actor_role
    from public.users as u where u.id = v_actor_id;
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
        100000 + (
          (('x' || pg_catalog.encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint)
          % 900000
        )
      )::text,
      6,
      '0'
    );

    begin
      select cl.id into v_link_id
        from public.caregiver_links as cl
       where cl.patient_id = v_actor_id
         and cl.caregiver_id is null
         and cl.status::text = 'pending'
       for update;

      if v_link_id is null then
        insert into public.caregiver_links (
          id,
          patient_id,
          pairing_code,
          pairing_code_expires_at,
          status,
          permissions_mask,
          updated_at
        ) values (
          pg_catalog.gen_random_uuid(),
          v_actor_id,
          v_code,
          v_expires_at,
          'pending',
          255,
          pg_catalog.now()
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

  return pg_catalog.jsonb_build_object('code', v_code, 'expires_at', v_expires_at);
end;
$function$;

revoke all on function public.generate_caregiver_pairing_code() from public, anon, authenticated;
grant execute on function public.generate_caregiver_pairing_code() to authenticated;
