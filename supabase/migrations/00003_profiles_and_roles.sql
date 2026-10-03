-- Migration: 00003_profiles_and_roles
-- Purpose: User profiles (extends auth.users) and role assignments

-- Profiles (one per auth.users row, created by trigger)
CREATE TABLE public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   text,
  phone       text, -- E.164 format +2547XXXXXXXX
  avatar_url  text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Role assignments (a user can have multiple roles with different scopes)
CREATE TABLE public.user_roles (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        app_role NOT NULL,
  region_id   uuid,       -- populated for regional_manager
  station_id  uuid,       -- populated for station_manager
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role, region_id, station_id)
);

CREATE INDEX idx_user_roles_user ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_role ON public.user_roles(role);

CREATE TRIGGER user_roles_updated_at
  BEFORE UPDATE ON public.user_roles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Private helper: check if current user has a given role
CREATE OR REPLACE FUNCTION private.has_role(_role app_role)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = _role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Private helper: check if current user has any admin-level role
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hq_admin', 'content_editor',
                   'regional_manager', 'support_agent', 'station_manager')
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Private helper: check if current user is in a specific region
CREATE OR REPLACE FUNCTION private.in_region(_region_id uuid)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'regional_manager'
      AND region_id = _region_id
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Private helper: check if current user owns/manages a specific station
CREATE OR REPLACE FUNCTION private.owns_station(_station_id uuid)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'station_manager'
      AND station_id = _station_id
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Private helper: check if user has any elevated role (not just customer)
CREATE OR REPLACE FUNCTION private.has_any_staff_role()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role != 'customer'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;
