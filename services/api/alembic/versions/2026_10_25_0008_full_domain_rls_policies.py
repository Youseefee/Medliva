"""Add full domain RLS policies for patient and caregiver data access.

Revision ID: 0008_full_domain_rls_policies
Revises: 0007_auth_users_sync_and_rls
Create Date: 2026-10-25 00:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0008_full_domain_rls_policies"
down_revision: str | None = "0007_auth_users_sync_and_rls"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PATIENT_TABLES = (
    "medications",
    "intake_logs",
    "vitals_logs",
    "emergency_contacts",
    "alerts",
    "prescriptions",
    "report_shares",
)


def upgrade() -> None:
    if op.get_bind().dialect.name != "postgresql":
        return

    # 1. drug_catalog: readable by all authenticated users and anon/public
    op.execute('DROP POLICY IF EXISTS "drug_catalog_select_all" ON public.drug_catalog;')
    op.execute(
        """
        CREATE POLICY "drug_catalog_select_all" ON public.drug_catalog
          FOR SELECT
          TO authenticated, anon
          USING (true);
        """
    )

    # 2. caregiver_links: participants (patient or caregiver) have full visibility and link management
    op.execute('DROP POLICY IF EXISTS "caregiver_links_select" ON public.caregiver_links;')
    op.execute(
        """
        CREATE POLICY "caregiver_links_select" ON public.caregiver_links
          FOR SELECT
          TO authenticated
          USING (patient_id = auth.uid() OR caregiver_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "caregiver_links_insert" ON public.caregiver_links;')
    op.execute(
        """
        CREATE POLICY "caregiver_links_insert" ON public.caregiver_links
          FOR INSERT
          TO authenticated
          WITH CHECK (patient_id = auth.uid() OR caregiver_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "caregiver_links_update" ON public.caregiver_links;')
    op.execute(
        """
        CREATE POLICY "caregiver_links_update" ON public.caregiver_links
          FOR UPDATE
          TO authenticated
          USING (patient_id = auth.uid() OR caregiver_id = auth.uid())
          WITH CHECK (patient_id = auth.uid() OR caregiver_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "caregiver_links_delete" ON public.caregiver_links;')
    op.execute(
        """
        CREATE POLICY "caregiver_links_delete" ON public.caregiver_links
          FOR DELETE
          TO authenticated
          USING (patient_id = auth.uid() OR caregiver_id = auth.uid());
        """
    )

    # 3. Patient tables (with patient_id column)
    for table in PATIENT_TABLES:
        # SELECT
        op.execute(f'DROP POLICY IF EXISTS "{table}_select" ON public.{table};')
        op.execute(
            f"""
            CREATE POLICY "{table}_select" ON public.{table}
              FOR SELECT
              TO authenticated
              USING (
                patient_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.caregiver_links
                  WHERE caregiver_id = auth.uid()
                    AND patient_id = {table}.patient_id
                    AND status IN ('active', 'accepted')
                )
              );
            """
        )

        # INSERT
        op.execute(f'DROP POLICY IF EXISTS "{table}_insert" ON public.{table};')
        op.execute(
            f"""
            CREATE POLICY "{table}_insert" ON public.{table}
              FOR INSERT
              TO authenticated
              WITH CHECK (
                patient_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.caregiver_links
                  WHERE caregiver_id = auth.uid()
                    AND patient_id = {table}.patient_id
                    AND status IN ('active', 'accepted')
                )
              );
            """
        )

        # UPDATE
        op.execute(f'DROP POLICY IF EXISTS "{table}_update" ON public.{table};')
        op.execute(
            f"""
            CREATE POLICY "{table}_update" ON public.{table}
              FOR UPDATE
              TO authenticated
              USING (
                patient_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.caregiver_links
                  WHERE caregiver_id = auth.uid()
                    AND patient_id = {table}.patient_id
                    AND status IN ('active', 'accepted')
                )
              )
              WITH CHECK (
                patient_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.caregiver_links
                  WHERE caregiver_id = auth.uid()
                    AND patient_id = {table}.patient_id
                    AND status IN ('active', 'accepted')
                )
              );
            """
        )

        # DELETE
        op.execute(f'DROP POLICY IF EXISTS "{table}_delete" ON public.{table};')
        op.execute(
            f"""
            CREATE POLICY "{table}_delete" ON public.{table}
              FOR DELETE
              TO authenticated
              USING (
                patient_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.caregiver_links
                  WHERE caregiver_id = auth.uid()
                    AND patient_id = {table}.patient_id
                    AND status IN ('active', 'accepted')
                )
              );
            """
        )

    # 4. schedules: linked via medication_id to medications (patient or authorized caregiver)
    op.execute('DROP POLICY IF EXISTS "schedules_select" ON public.schedules;')
    op.execute(
        """
        CREATE POLICY "schedules_select" ON public.schedules
          FOR SELECT
          TO authenticated
          USING (
            EXISTS (
              SELECT 1 FROM public.medications m
              WHERE m.id = schedules.medication_id
                AND (
                  m.patient_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.caregiver_links cl
                    WHERE cl.caregiver_id = auth.uid()
                      AND cl.patient_id = m.patient_id
                      AND cl.status IN ('active', 'accepted')
                  )
                )
            )
          );
        """
    )

    op.execute('DROP POLICY IF EXISTS "schedules_insert" ON public.schedules;')
    op.execute(
        """
        CREATE POLICY "schedules_insert" ON public.schedules
          FOR INSERT
          TO authenticated
          WITH CHECK (
            EXISTS (
              SELECT 1 FROM public.medications m
              WHERE m.id = schedules.medication_id
                AND (
                  m.patient_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.caregiver_links cl
                    WHERE cl.caregiver_id = auth.uid()
                      AND cl.patient_id = m.patient_id
                      AND cl.status IN ('active', 'accepted')
                  )
                )
            )
          );
        """
    )

    op.execute('DROP POLICY IF EXISTS "schedules_update" ON public.schedules;')
    op.execute(
        """
        CREATE POLICY "schedules_update" ON public.schedules
          FOR UPDATE
          TO authenticated
          USING (
            EXISTS (
              SELECT 1 FROM public.medications m
              WHERE m.id = schedules.medication_id
                AND (
                  m.patient_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.caregiver_links cl
                    WHERE cl.caregiver_id = auth.uid()
                      AND cl.patient_id = m.patient_id
                      AND cl.status IN ('active', 'accepted')
                  )
                )
            )
          )
          WITH CHECK (
            EXISTS (
              SELECT 1 FROM public.medications m
              WHERE m.id = schedules.medication_id
                AND (
                  m.patient_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.caregiver_links cl
                    WHERE cl.caregiver_id = auth.uid()
                      AND cl.patient_id = m.patient_id
                      AND cl.status IN ('active', 'accepted')
                  )
                )
            )
          );
        """
    )

    op.execute('DROP POLICY IF EXISTS "schedules_delete" ON public.schedules;')
    op.execute(
        """
        CREATE POLICY "schedules_delete" ON public.schedules
          FOR DELETE
          TO authenticated
          USING (
            EXISTS (
              SELECT 1 FROM public.medications m
              WHERE m.id = schedules.medication_id
                AND (
                  m.patient_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.caregiver_links cl
                    WHERE cl.caregiver_id = auth.uid()
                      AND cl.patient_id = m.patient_id
                      AND cl.status IN ('active', 'accepted')
                  )
                )
            )
          );
        """
    )

    # 5. devices: owned by the user (user_id = auth.uid())
    op.execute('DROP POLICY IF EXISTS "devices_select_own" ON public.devices;')
    op.execute(
        """
        CREATE POLICY "devices_select_own" ON public.devices
          FOR SELECT
          TO authenticated
          USING (user_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "devices_insert_own" ON public.devices;')
    op.execute(
        """
        CREATE POLICY "devices_insert_own" ON public.devices
          FOR INSERT
          TO authenticated
          WITH CHECK (user_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "devices_update_own" ON public.devices;')
    op.execute(
        """
        CREATE POLICY "devices_update_own" ON public.devices
          FOR UPDATE
          TO authenticated
          USING (user_id = auth.uid())
          WITH CHECK (user_id = auth.uid());
        """
    )

    op.execute('DROP POLICY IF EXISTS "devices_delete_own" ON public.devices;')
    op.execute(
        """
        CREATE POLICY "devices_delete_own" ON public.devices
          FOR DELETE
          TO authenticated
          USING (user_id = auth.uid());
        """
    )


def downgrade() -> None:
    if op.get_bind().dialect.name != "postgresql":
        return

    # 5. devices
    op.execute('DROP POLICY IF EXISTS "devices_delete_own" ON public.devices;')
    op.execute('DROP POLICY IF EXISTS "devices_update_own" ON public.devices;')
    op.execute('DROP POLICY IF EXISTS "devices_insert_own" ON public.devices;')
    op.execute('DROP POLICY IF EXISTS "devices_select_own" ON public.devices;')

    # 4. schedules
    op.execute('DROP POLICY IF EXISTS "schedules_delete" ON public.schedules;')
    op.execute('DROP POLICY IF EXISTS "schedules_update" ON public.schedules;')
    op.execute('DROP POLICY IF EXISTS "schedules_insert" ON public.schedules;')
    op.execute('DROP POLICY IF EXISTS "schedules_select" ON public.schedules;')

    # 3. Patient tables
    for table in reversed(PATIENT_TABLES):
        op.execute(f'DROP POLICY IF EXISTS "{table}_delete" ON public.{table};')
        op.execute(f'DROP POLICY IF EXISTS "{table}_update" ON public.{table};')
        op.execute(f'DROP POLICY IF EXISTS "{table}_insert" ON public.{table};')
        op.execute(f'DROP POLICY IF EXISTS "{table}_select" ON public.{table};')

    # 2. caregiver_links
    op.execute('DROP POLICY IF EXISTS "caregiver_links_delete" ON public.caregiver_links;')
    op.execute('DROP POLICY IF EXISTS "caregiver_links_update" ON public.caregiver_links;')
    op.execute('DROP POLICY IF EXISTS "caregiver_links_insert" ON public.caregiver_links;')
    op.execute('DROP POLICY IF EXISTS "caregiver_links_select" ON public.caregiver_links;')

    # 1. drug_catalog
    op.execute('DROP POLICY IF EXISTS "drug_catalog_select_all" ON public.drug_catalog;')
