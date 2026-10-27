-- Supabase writes and the medication RPC generate IDs in the database.
alter table public.medications
  alter column id set default pg_catalog.gen_random_uuid();

alter table public.schedules
  alter column id set default pg_catalog.gen_random_uuid();
