-- Shared drug reference data only; no patient demo records.
insert into public.drug_catalog (id, trade_name, active_ingredient, strength, form)
values
  ('e0707495-bdd6-4316-9891-f396855fde88', 'Aspirin Protect 100mg', 'Acetylsalicylic acid', '100mg', 'قرص'),
  ('3decb77c-0b0b-4e30-a9a2-c94d85e13c52', 'Augmentin 1g', 'Amoxicillin / Clavulanate', '1000mg', 'قرص'),
  ('5aef88c7-32e5-4217-876a-deeffd628615', 'Concor 2.5mg', 'Bisoprolol', '2.5mg', 'قرص'),
  ('f740ce2e-d50e-4e47-9d22-569aa4a586e9', 'Concor 5mg', 'Bisoprolol', '5mg', 'قرص'),
  ('a280490a-9c7f-42f1-b616-ae590c7c6291', 'Glucophage 1000mg', 'Metformin', '1000mg', 'قرص'),
  ('22bcf159-02a0-45d1-8cf4-274dd9250895', 'Glucophage 500mg', 'Metformin', '500mg', 'قرص'),
  ('601b851d-b664-4557-a2b8-623206a56d4d', 'Januvia 100mg', 'Sitagliptin', '100mg', 'قرص'),
  ('6e86b0aa-70eb-46ab-bb25-e2375d4caa47', 'Lipitor 20mg', 'Atorvastatin', '20mg', 'قرص'),
  ('d358d63d-936c-437a-8fce-f8a767b0c3f6', 'Panadol Extra', 'Paracetamol / Caffeine', '500mg', 'قرص'),
  ('09af65ac-fb0b-44a4-a97d-54ba4cf430f8', 'Plavix 75mg', 'Clopidogrel', '75mg', 'قرص')
on conflict (id) do nothing;
