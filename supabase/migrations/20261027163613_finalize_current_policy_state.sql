-- Recreate the production RLS boundary and table grants after all application
-- RPC migrations. Run the same policies on fresh local databases and cloud.

do $$
declare
  v_policy record;
begin
  for v_policy in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = any (array[
        'users', 'caregiver_links', 'drug_catalog', 'medications', 'schedules',
        'intake_logs', 'vitals_logs', 'prescriptions', 'emergency_contacts',
        'devices', 'report_shares', 'alerts'
      ])
  loop
    execute format(
      'drop policy %I on %I.%I',
      v_policy.policyname,
      v_policy.schemaname,
      v_policy.tablename
    );
  end loop;
end;
$$;

alter table public.users enable row level security;
alter table public.caregiver_links enable row level security;
alter table public.drug_catalog enable row level security;
alter table public.medications enable row level security;
alter table public.schedules enable row level security;
alter table public.intake_logs enable row level security;
alter table public.vitals_logs enable row level security;
alter table public.prescriptions enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.devices enable row level security;
alter table public.report_shares enable row level security;
alter table public.alerts enable row level security;

create policy users_select_self_or_active_caregiver on public.users
  for select to authenticated
  using (
    id = (select auth.uid())
    or exists (
      select 1 from public.caregiver_links cl
      where cl.caregiver_id = (select auth.uid())
        and cl.patient_id = users.id
        and cl.status in ('active', 'accepted')
    )
  );

create policy users_update_self on public.users
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy caregiver_links_select_participant on public.caregiver_links
  for select to authenticated
  using (
    patient_id = (select auth.uid())
    or (
      caregiver_id = (select auth.uid())
      and status in ('active', 'accepted')
    )
  );

create policy drug_catalog_select_all on public.drug_catalog
  for select to anon, authenticated
  using (true);

create policy alerts_select on public.alerts
  for select to authenticated
  using (
    patient_id = (select auth.uid())
    or exists (
      select 1 from public.caregiver_links cl
      where cl.caregiver_id = (select auth.uid())
        and cl.patient_id = alerts.patient_id
        and cl.status in ('active', 'accepted')
    )
  );

create policy devices_select_own on public.devices
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy devices_insert_own on public.devices
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy devices_update_own on public.devices
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy devices_delete_own on public.devices
  for delete to authenticated
  using (user_id = (select auth.uid()));

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'medications', 'intake_logs', 'vitals_logs', 'emergency_contacts',
    'prescriptions', 'report_shares'
  ]
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using (' ||
      '(patient_id = (select auth.uid())) or exists (' ||
      'select 1 from public.caregiver_links cl ' ||
      'where cl.caregiver_id = (select auth.uid()) ' ||
      'and cl.patient_id = %I.patient_id ' ||
      'and cl.status in (''active'', ''accepted'')))',
      v_table || '_select', v_table, v_table
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (' ||
      '(patient_id = (select auth.uid())) or exists (' ||
      'select 1 from public.caregiver_links cl ' ||
      'where cl.caregiver_id = (select auth.uid()) ' ||
      'and cl.patient_id = %I.patient_id ' ||
      'and cl.status in (''active'', ''accepted'')))',
      v_table || '_insert', v_table, v_table
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (' ||
      '(patient_id = (select auth.uid())) or exists (' ||
      'select 1 from public.caregiver_links cl ' ||
      'where cl.caregiver_id = (select auth.uid()) ' ||
      'and cl.patient_id = %I.patient_id ' ||
      'and cl.status in (''active'', ''accepted''))) ' ||
      'with check ((patient_id = (select auth.uid())) or exists (' ||
      'select 1 from public.caregiver_links cl ' ||
      'where cl.caregiver_id = (select auth.uid()) ' ||
      'and cl.patient_id = %I.patient_id ' ||
      'and cl.status in (''active'', ''accepted'')))',
      v_table || '_update', v_table, v_table, v_table
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using (' ||
      '(patient_id = (select auth.uid())) or exists (' ||
      'select 1 from public.caregiver_links cl ' ||
      'where cl.caregiver_id = (select auth.uid()) ' ||
      'and cl.patient_id = %I.patient_id ' ||
      'and cl.status in (''active'', ''accepted'')))',
      v_table || '_delete', v_table, v_table
    );
  end loop;
end;
$$;

create policy schedules_select on public.schedules
  for select to authenticated
  using (
    exists (
      select 1 from public.medications m
      where m.id = schedules.medication_id
        and (
          m.patient_id = (select auth.uid())
          or exists (
            select 1 from public.caregiver_links cl
            where cl.caregiver_id = (select auth.uid())
              and cl.patient_id = m.patient_id
              and cl.status in ('active', 'accepted')
          )
        )
    )
  );

create policy schedules_insert on public.schedules
  for insert to authenticated
  with check (
    exists (
      select 1 from public.medications m
      where m.id = schedules.medication_id
        and (
          m.patient_id = (select auth.uid())
          or exists (
            select 1 from public.caregiver_links cl
            where cl.caregiver_id = (select auth.uid())
              and cl.patient_id = m.patient_id
              and cl.status in ('active', 'accepted')
          )
        )
    )
  );

create policy schedules_update on public.schedules
  for update to authenticated
  using (
    exists (
      select 1 from public.medications m
      where m.id = schedules.medication_id
        and (
          m.patient_id = (select auth.uid())
          or exists (
            select 1 from public.caregiver_links cl
            where cl.caregiver_id = (select auth.uid())
              and cl.patient_id = m.patient_id
              and cl.status in ('active', 'accepted')
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.medications m
      where m.id = schedules.medication_id
        and (
          m.patient_id = (select auth.uid())
          or exists (
            select 1 from public.caregiver_links cl
            where cl.caregiver_id = (select auth.uid())
              and cl.patient_id = m.patient_id
              and cl.status in ('active', 'accepted')
          )
        )
    )
  );

create policy schedules_delete on public.schedules
  for delete to authenticated
  using (
    exists (
      select 1 from public.medications m
      where m.id = schedules.medication_id
        and (
          m.patient_id = (select auth.uid())
          or exists (
            select 1 from public.caregiver_links cl
            where cl.caregiver_id = (select auth.uid())
              and cl.patient_id = m.patient_id
              and cl.status in ('active', 'accepted')
          )
        )
    )
  );

revoke all on table public.users from public, anon, authenticated;
revoke all on table public.caregiver_links from public, anon, authenticated;
revoke all on table public.drug_catalog from public, anon, authenticated;
revoke all on table public.medications from public, anon, authenticated;
revoke all on table public.schedules from public, anon, authenticated;
revoke all on table public.intake_logs from public, anon, authenticated;
revoke all on table public.vitals_logs from public, anon, authenticated;
revoke all on table public.prescriptions from public, anon, authenticated;
revoke all on table public.emergency_contacts from public, anon, authenticated;
revoke all on table public.devices from public, anon, authenticated;
revoke all on table public.report_shares from public, anon, authenticated;
revoke all on table public.alerts from public, anon, authenticated;

grant select on table public.users to authenticated;
grant update (name, role, language, timezone, birth_date, address, updated_at)
  on table public.users to authenticated;
grant select on table public.caregiver_links to authenticated;
grant select on table public.drug_catalog to anon, authenticated;
grant select, insert, update, delete on table public.medications to authenticated;
grant select, insert, update, delete on table public.schedules to authenticated;
grant select, insert, update, delete on table public.intake_logs to authenticated;
grant select, insert, update, delete on table public.vitals_logs to authenticated;
grant select, insert, update, delete on table public.prescriptions to authenticated;
grant select, insert, update, delete on table public.emergency_contacts to authenticated;
grant select on table public.alerts to authenticated;

grant all on table public.users to service_role;
grant all on table public.caregiver_links to service_role;
grant all on table public.drug_catalog to service_role;
grant all on table public.medications to service_role;
grant all on table public.schedules to service_role;
grant all on table public.intake_logs to service_role;
grant all on table public.vitals_logs to service_role;
grant all on table public.prescriptions to service_role;
grant all on table public.emergency_contacts to service_role;
grant all on table public.devices to service_role;
grant all on table public.report_shares to service_role;
grant all on table public.alerts to service_role;

-- The old migration runner is gone; retain schema history in Supabase migrations.
drop table if exists public.alembic_version;
