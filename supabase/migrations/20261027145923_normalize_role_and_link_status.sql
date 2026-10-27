-- Use the lowercase enum values already used by Flutter and Supabase RPCs.
update public.users
   set role = pg_catalog.lower(role)
 where role <> pg_catalog.lower(role);

update public.caregiver_links
   set status = pg_catalog.lower(status::text)
 where status::text <> pg_catalog.lower(status::text);

drop index if exists public.caregiver_links_one_pending_patient;
create unique index caregiver_links_one_pending_patient
  on public.caregiver_links (patient_id)
  where pg_catalog.lower(status::text) = 'pending' and caregiver_id is null;

drop index if exists public.caregiver_links_pending_pairing_code;
create unique index caregiver_links_pending_pairing_code
  on public.caregiver_links (pairing_code)
  where pg_catalog.lower(status::text) = 'pending' and pairing_code is not null;

create or replace function public.normalize_user_role_case()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.role := pg_catalog.lower(new.role::text);
  return new;
end;
$function$;

create or replace function public.normalize_caregiver_link_status_case()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.status := pg_catalog.lower(new.status::text);
  return new;
end;
$function$;

drop trigger if exists normalize_user_role_case on public.users;
create trigger normalize_user_role_case
  before insert or update of role on public.users
  for each row execute function public.normalize_user_role_case();

drop trigger if exists normalize_caregiver_link_status_case on public.caregiver_links;
create trigger normalize_caregiver_link_status_case
  before insert or update of status on public.caregiver_links
  for each row execute function public.normalize_caregiver_link_status_case();
