-- Keep prescription and medication images private. Files must live under the
-- patient's auth user ID; only that patient and their active caregivers can
-- read, upload, replace, or delete them.

DROP POLICY IF EXISTS "medliva_patient_images_select" ON storage.objects;
CREATE POLICY "medliva_patient_images_select"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id IN ('prescriptions', 'pill-images')
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      OR EXISTS (
        SELECT 1
        FROM public.caregiver_links AS cl
        WHERE cl.patient_id::text = (storage.foldername(name))[1]
          AND cl.caregiver_id = (SELECT auth.uid())
          AND cl.status::text IN ('active', 'accepted')
      )
    )
  );

DROP POLICY IF EXISTS "medliva_patient_images_insert" ON storage.objects;
CREATE POLICY "medliva_patient_images_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('prescriptions', 'pill-images')
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      OR EXISTS (
        SELECT 1
        FROM public.caregiver_links AS cl
        WHERE cl.patient_id::text = (storage.foldername(name))[1]
          AND cl.caregiver_id = (SELECT auth.uid())
          AND cl.status::text IN ('active', 'accepted')
      )
    )
  );

DROP POLICY IF EXISTS "medliva_patient_images_update" ON storage.objects;
CREATE POLICY "medliva_patient_images_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('prescriptions', 'pill-images')
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      OR EXISTS (
        SELECT 1
        FROM public.caregiver_links AS cl
        WHERE cl.patient_id::text = (storage.foldername(name))[1]
          AND cl.caregiver_id = (SELECT auth.uid())
          AND cl.status::text IN ('active', 'accepted')
      )
    )
  )
  WITH CHECK (
    bucket_id IN ('prescriptions', 'pill-images')
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      OR EXISTS (
        SELECT 1
        FROM public.caregiver_links AS cl
        WHERE cl.patient_id::text = (storage.foldername(name))[1]
          AND cl.caregiver_id = (SELECT auth.uid())
          AND cl.status::text IN ('active', 'accepted')
      )
    )
  );

DROP POLICY IF EXISTS "medliva_patient_images_delete" ON storage.objects;
CREATE POLICY "medliva_patient_images_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id IN ('prescriptions', 'pill-images')
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      OR EXISTS (
        SELECT 1
        FROM public.caregiver_links AS cl
        WHERE cl.patient_id::text = (storage.foldername(name))[1]
          AND cl.caregiver_id = (SELECT auth.uid())
          AND cl.status::text IN ('active', 'accepted')
      )
    )
  );
