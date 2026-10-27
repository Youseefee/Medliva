-- Limit profile visibility to the owner and caregivers with an active link.
drop policy if exists "users_select_authenticated" on public.users;
drop policy if exists "users_select_self_or_active_caregiver" on public.users;
create policy "users_select_self_or_active_caregiver" on public.users
  for select
  to authenticated
  using (
    id = (select auth.uid())
    or exists (
      select 1
      from public.caregiver_links as cl
      where cl.caregiver_id = (select auth.uid())
        and cl.patient_id = users.id
        and cl.status in ('active', 'accepted')
    )
  );

drop policy if exists "users_update_own" on public.users;
drop policy if exists "users_update_self" on public.users;
create policy "users_update_self" on public.users
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Clients cannot create arbitrary profile rows or change protected fields.
drop policy if exists "users_insert_own" on public.users;
revoke all on table public.users from public, anon, authenticated;
grant select on table public.users to authenticated;
grant update (name, role, language, timezone, birth_date, address, updated_at)
  on table public.users to authenticated;

-- Keep the existing patient/caregiver role switch, but block client-side admin promotion.
create or replace function public.prevent_user_admin_role_escalation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.role::text = 'admin' and old.role::text <> 'admin' then
    raise exception 'Only trusted server operations can grant the admin role'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke all on function public.prevent_user_admin_role_escalation() from public, anon, authenticated;
drop trigger if exists users_prevent_role_escalation on public.users;
create trigger users_prevent_role_escalation
  before update of role on public.users
  for each row
  execute function public.prevent_user_admin_role_escalation();

-- Auth profile sync is the only profile creation path. Do not let signup metadata
-- assign admin, and do not overwrite profile edits on later auth.users updates.
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
    new.email,
    new.phone,
    v_name,
    v_role,
    v_lang,
    'Africa/Cairo',
    pg_catalog.now(),
    pg_catalog.now()
  )
  on conflict (id) do update set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    updated_at = pg_catalog.now();

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
