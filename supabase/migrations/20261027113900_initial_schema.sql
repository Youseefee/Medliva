-- Bootstrap the application schema for a fresh Supabase project.
-- This intentionally mirrors the current production tables and stays safe to
-- apply to the already-provisioned project.

create table if not exists public.users (
  id uuid not null,
  phone varchar(20),
  name varchar(100),
  role varchar(9) not null default 'patient',
  language varchar(10) not null default 'ar',
  timezone varchar(50) not null default 'Africa/Cairo',
  birth_date date,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  email varchar(320),
  constraint pk_users primary key (id)
);

create table if not exists public.drug_catalog (
  trade_name varchar(150) not null,
  active_ingredient varchar(150),
  strength varchar(50),
  form varchar(50),
  manufacturer varchar(100),
  price_egp double precision,
  id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_drug_catalog primary key (id)
);

create table if not exists public.caregiver_links (
  caregiver_id uuid,
  patient_id uuid not null,
  pairing_code varchar(6),
  pairing_code_expires_at timestamptz,
  status varchar(7) not null,
  permissions_mask integer not null,
  linked_at timestamptz,
  id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_caregiver_links primary key (id),
  constraint fk_caregiver_links_caregiver_id_users
    foreign key (caregiver_id) references public.users(id) on delete cascade,
  constraint fk_caregiver_links_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade,
  constraint uq_caregiver_links_pair unique (caregiver_id, patient_id)
);

create table if not exists public.devices (
  user_id uuid not null,
  fcm_token varchar(255) not null,
  platform varchar(20) not null,
  app_version varchar(20),
  last_seen timestamptz not null default now(),
  id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_devices primary key (id),
  constraint fk_devices_user_id_users
    foreign key (user_id) references public.users(id) on delete cascade
);

create table if not exists public.emergency_contacts (
  patient_id uuid not null,
  name varchar(100) not null,
  phone varchar(20) not null,
  relationship varchar(50),
  is_primary boolean not null,
  notify_call boolean not null,
  id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_emergency_contacts primary key (id),
  constraint fk_emergency_contacts_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade
);

create table if not exists public.medications (
  patient_id uuid not null,
  drug_catalog_id uuid,
  name varchar(150) not null,
  trade_name varchar(150),
  active_ingredient varchar(150),
  form varchar(50) not null,
  strength varchar(50),
  pill_image_url varchar(500),
  stock_count integer not null,
  alert_threshold_days integer not null,
  expiry_date date,
  is_active boolean not null,
  id uuid not null default pg_catalog.gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_medications primary key (id),
  constraint fk_medications_drug_catalog_id_drug_catalog
    foreign key (drug_catalog_id) references public.drug_catalog(id) on delete set null,
  constraint fk_medications_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade
);

create table if not exists public.schedules (
  medication_id uuid not null,
  time_of_day time without time zone not null,
  days_mask integer not null,
  dose_amount double precision not null,
  meal_relation varchar(11) not null,
  instructions_ar varchar(255),
  start_date date,
  end_date date,
  is_active boolean not null,
  id uuid not null default pg_catalog.gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_schedules primary key (id),
  constraint fk_schedules_medication_id_medications
    foreign key (medication_id) references public.medications(id) on delete cascade
);

create table if not exists public.intake_logs (
  client_uuid varchar(64) not null,
  schedule_id uuid not null,
  patient_id uuid not null,
  scheduled_time timestamptz not null,
  actual_time timestamptz,
  status varchar(7) not null,
  reason varchar(255),
  logged_offline boolean not null,
  id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_intake_logs primary key (id),
  constraint fk_intake_logs_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade,
  constraint fk_intake_logs_schedule_id_schedules
    foreign key (schedule_id) references public.schedules(id) on delete cascade
);

create table if not exists public.vitals_logs (
  client_uuid varchar(64),
  patient_id uuid not null,
  type varchar(7) not null,
  value_primary double precision not null,
  value_secondary double precision,
  meal_context varchar(50),
  band varchar(10) not null,
  recorded_at timestamptz not null default now(),
  id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_vitals_logs primary key (id),
  constraint fk_vitals_logs_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade
);

create table if not exists public.prescriptions (
  patient_id uuid not null,
  image_url varchar(500),
  doctor_name varchar(150),
  raw_extracted_json text,
  confidence double precision not null,
  verified_at timestamptz,
  verified_by uuid,
  id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_prescriptions primary key (id),
  constraint fk_prescriptions_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade,
  constraint fk_prescriptions_verified_by_users
    foreign key (verified_by) references public.users(id) on delete set null
);

create table if not exists public.report_shares (
  patient_id uuid not null,
  token_hash varchar(64) not null,
  scope varchar(50) not null,
  expires_at timestamptz not null,
  views_count integer not null,
  revoked boolean not null,
  id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_report_shares primary key (id),
  constraint fk_report_shares_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade
);

create table if not exists public.alerts (
  patient_id uuid not null,
  type varchar(14) not null,
  tier integer not null,
  payload_json text,
  sent_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  id uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pk_alerts primary key (id),
  constraint fk_alerts_patient_id_users
    foreign key (patient_id) references public.users(id) on delete cascade
);

create unique index if not exists ix_users_phone on public.users (phone);
create unique index if not exists ix_users_email on public.users (email);
create index if not exists ix_caregiver_links_caregiver_id on public.caregiver_links (caregiver_id);
create index if not exists ix_caregiver_links_pairing_code on public.caregiver_links (pairing_code);
create index if not exists ix_caregiver_links_patient_id on public.caregiver_links (patient_id);
create unique index if not exists caregiver_links_one_pending_patient
  on public.caregiver_links (patient_id)
  where lower(status) = 'pending' and caregiver_id is null;
create unique index if not exists caregiver_links_pending_pairing_code
  on public.caregiver_links (pairing_code)
  where lower(status) = 'pending' and pairing_code is not null;
create unique index if not exists ix_devices_fcm_token on public.devices (fcm_token);
create index if not exists ix_devices_user_id on public.devices (user_id);
create index if not exists ix_drug_catalog_trade_name on public.drug_catalog (trade_name);
create index if not exists ix_emergency_contacts_patient_id on public.emergency_contacts (patient_id);
create index if not exists ix_medications_drug_catalog_id on public.medications (drug_catalog_id);
create index if not exists ix_medications_patient_id on public.medications (patient_id);
create index if not exists ix_schedules_medication_id on public.schedules (medication_id);
create unique index if not exists ix_intake_logs_client_uuid on public.intake_logs (client_uuid);
create index if not exists ix_intake_logs_patient_id on public.intake_logs (patient_id);
create index if not exists ix_intake_logs_schedule_id on public.intake_logs (schedule_id);
create index if not exists ix_intake_logs_scheduled_time on public.intake_logs (scheduled_time);
create unique index if not exists ix_vitals_logs_client_uuid on public.vitals_logs (client_uuid);
create index if not exists ix_vitals_logs_patient_id on public.vitals_logs (patient_id);
create index if not exists ix_vitals_logs_recorded_at on public.vitals_logs (recorded_at);
create index if not exists ix_prescriptions_patient_id on public.prescriptions (patient_id);
create index if not exists ix_prescriptions_verified_by on public.prescriptions (verified_by);
create index if not exists ix_report_shares_patient_id on public.report_shares (patient_id);
create unique index if not exists ix_report_shares_token_hash on public.report_shares (token_hash);
create index if not exists ix_alerts_patient_id on public.alerts (patient_id);

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

insert into storage.buckets (id, name, public)
values ('prescriptions', 'prescriptions', false), ('pill-images', 'pill-images', false)
on conflict (id) do update set public = excluded.public;
