-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql;

-- 1. Create Villages table
CREATE TABLE IF NOT EXISTS public.villages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  moo INTEGER NOT NULL,
  sub_district TEXT NOT NULL,
  district TEXT NOT NULL,
  province TEXT NOT NULL,
  postcode TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT villages_unique_key UNIQUE (name, moo, sub_district, district, province)
);

-- Trigger to update updated_at for villages
CREATE TRIGGER update_villages_updated_at
  BEFORE UPDATE ON public.villages
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 2. Create VHV (Village Health Volunteers) / users table
CREATE TABLE IF NOT EXISTS public.vhvs (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'vhv',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Trigger to update updated_at for vhvs
CREATE TRIGGER update_vhvs_updated_at
  BEFORE UPDATE ON public.vhvs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 3. Create VHV at village table (Junction table)
CREATE TABLE IF NOT EXISTS public.vhv_villages (
  vhv_id UUID NOT NULL REFERENCES public.vhvs(id) ON DELETE CASCADE,
  village_id UUID NOT NULL REFERENCES public.villages(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  PRIMARY KEY (vhv_id, village_id)
);

-- Trigger to update updated_at for vhv_villages
CREATE TRIGGER update_vhv_villages_updated_at
  BEFORE UPDATE ON public.vhv_villages
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 4. Create Surveys table (การสำรวจและกำจัดลูกน้ำยุงลาย รายหมู่บ้าน)
CREATE TABLE IF NOT EXISTS public.surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  village_id UUID NOT NULL REFERENCES public.villages(id) ON DELETE CASCADE,
  
  -- หมู่บ้าน/ชุมชน (Households & Community)
  households_surveyed INTEGER NOT NULL DEFAULT 0,
  households_positive INTEGER NOT NULL DEFAULT 0,
  hi NUMERIC GENERATED ALWAYS AS (
    CASE WHEN households_surveyed > 0 THEN ROUND((households_positive::numeric / households_surveyed::numeric) * 100, 2) ELSE 0 END
  ) STORED,
  
  containers_surveyed INTEGER NOT NULL DEFAULT 0,
  containers_positive INTEGER NOT NULL DEFAULT 0,
  ci NUMERIC GENERATED ALWAYS AS (
    CASE WHEN containers_surveyed > 0 THEN ROUND((containers_positive::numeric / containers_surveyed::numeric) * 100, 2) ELSE 0 END
  ) STORED,

  -- โรงเรียน (School)
  school_containers_surveyed INTEGER NOT NULL DEFAULT 0,
  school_containers_positive INTEGER NOT NULL DEFAULT 0,

  -- โรงพยาบาล (Hospital)
  hospital_containers_surveyed INTEGER NOT NULL DEFAULT 0,
  hospital_containers_positive INTEGER NOT NULL DEFAULT 0,

  -- โรงงาน (Factory)
  factory_containers_surveyed INTEGER NOT NULL DEFAULT 0,
  factory_containers_positive INTEGER NOT NULL DEFAULT 0,

  -- สถานที่ราชการ (Government/Public Office)
  public_office_containers_surveyed INTEGER NOT NULL DEFAULT 0,
  public_office_containers_positive INTEGER NOT NULL DEFAULT 0,

  -- Audit metadata
  created_by UUID REFERENCES public.vhvs(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID REFERENCES public.vhvs(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Trigger to update updated_at for surveys
CREATE TRIGGER update_surveys_updated_at
  BEFORE UPDATE ON public.surveys
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 5. Trigger to automatically create VHV profile when a new user registers in Supabase auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.vhvs (id, name, email, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'vhv')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
