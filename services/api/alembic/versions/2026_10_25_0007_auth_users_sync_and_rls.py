"""Add public.users sync trigger and RLS policies for Supabase Auth.

Revision ID: 0007_auth_users_sync_and_rls
Revises: 0006_supabase_auth
Create Date: 2026-10-25 00:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0007_auth_users_sync_and_rls"
down_revision: str | None = "0006_supabase_auth"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. Sync user function in public schema
    op.execute(
        """
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS trigger
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        DECLARE
          v_role text;
          v_name text;
          v_lang text;
        BEGIN
          v_role := LOWER(COALESCE(NEW.raw_user_meta_data->>'role', 'patient'));
          IF v_role NOT IN ('patient', 'caregiver', 'admin') THEN
            v_role := 'patient';
          END IF;

          v_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', '');
          v_lang := COALESCE(NEW.raw_user_meta_data->>'language', 'ar');

          INSERT INTO public.users (id, email, phone, name, role, language, timezone, created_at, updated_at)
          VALUES (
            NEW.id,
            NEW.email,
            NEW.phone,
            v_name,
            v_role,
            v_lang,
            'Africa/Cairo',
            NOW(),
            NOW()
          )
          ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            phone = COALESCE(EXCLUDED.phone, public.users.phone),
            name = CASE 
              WHEN EXCLUDED.name IS NOT NULL AND EXCLUDED.name <> '' THEN EXCLUDED.name 
              ELSE public.users.name 
            END,
            role = COALESCE(EXCLUDED.role, public.users.role),
            updated_at = NOW();

          RETURN NEW;
        END;
        $$;
        """
    )

    # 2. Trigger on auth.users
    op.execute("DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;")
    op.execute(
        """
        CREATE TRIGGER on_auth_user_created
          AFTER INSERT OR UPDATE ON auth.users
          FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
        """
    )

    # 3. RLS policies on public.users
    op.execute('DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;')
    op.execute(
        """
        CREATE POLICY "users_select_authenticated" ON public.users
          FOR SELECT
          TO authenticated
          USING (true);
        """
    )

    op.execute('DROP POLICY IF EXISTS "users_insert_own" ON public.users;')
    op.execute(
        """
        CREATE POLICY "users_insert_own" ON public.users
          FOR INSERT
          TO authenticated
          WITH CHECK (auth.uid() = id);
        """
    )

    op.execute('DROP POLICY IF EXISTS "users_update_own" ON public.users;')
    op.execute(
        """
        CREATE POLICY "users_update_own" ON public.users
          FOR UPDATE
          TO authenticated
          USING (auth.uid() = id)
          WITH CHECK (auth.uid() = id);
        """
    )


def downgrade() -> None:
    op.execute('DROP POLICY IF EXISTS "users_update_own" ON public.users;')
    op.execute('DROP POLICY IF EXISTS "users_insert_own" ON public.users;')
    op.execute('DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;')
    op.execute("DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;")
    op.execute("DROP FUNCTION IF EXISTS public.handle_new_user();")
