-- Migration: 00004_geography
-- Purpose: Regions, counties (47 official Kenya), and towns with PostGIS

CREATE TABLE public.regions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  slug        text NOT NULL UNIQUE,
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER regions_updated_at
  BEFORE UPDATE ON public.regions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.counties (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  slug        text NOT NULL UNIQUE,
  code        int UNIQUE, -- official county code 1-47
  region_id   uuid NOT NULL REFERENCES public.regions(id) ON DELETE RESTRICT,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_counties_region ON public.counties(region_id);

CREATE TRIGGER counties_updated_at
  BEFORE UPDATE ON public.counties
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.towns (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                    text NOT NULL,
  slug                    text NOT NULL UNIQUE,
  county_id               uuid NOT NULL REFERENCES public.counties(id) ON DELETE RESTRICT,
  region_id               uuid NOT NULL REFERENCES public.regions(id) ON DELETE RESTRICT,
  tier                    town_tier NOT NULL DEFAULT 'town',
  location                geography(Point, 4326),
  price_reference_town_id uuid REFERENCES public.towns(id) ON DELETE SET NULL,
  intro                   text, -- admin-editable town intro for town pages
  is_active               boolean NOT NULL DEFAULT true,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_towns_county ON public.towns(county_id);
CREATE INDEX idx_towns_region ON public.towns(region_id);
CREATE INDEX idx_towns_location ON public.towns USING GIST(location);
CREATE INDEX idx_towns_slug ON public.towns(slug);

CREATE TRIGGER towns_updated_at
  BEFORE UPDATE ON public.towns
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Add FK for user_roles.region_id now that regions table exists
ALTER TABLE public.user_roles
  ADD CONSTRAINT fk_user_roles_region
    FOREIGN KEY (region_id) REFERENCES public.regions(id) ON DELETE SET NULL;

CREATE INDEX idx_user_roles_region ON public.user_roles(region_id);
