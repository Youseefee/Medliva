-- These tables were previously assigned UUIDs by SQLAlchemy before inserts.
-- Supabase/PostgREST writers need database defaults after the migration.
alter table public.alerts
  alter column id set default pg_catalog.gen_random_uuid();
alter table public.devices
  alter column id set default pg_catalog.gen_random_uuid();
alter table public.emergency_contacts
  alter column id set default pg_catalog.gen_random_uuid();
alter table public.report_shares
  alter column id set default pg_catalog.gen_random_uuid();
