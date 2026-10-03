-- Migration: 00006_stations
-- Purpose: Station network, franchisee orgs, station-services, station media

-- Franchisee organisations
CREATE TABLE public.franchisee_orgs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  registration  text, -- company reg number (encrypted at rest if sensitive)
  contact_name  text,
  contact_email text,
  contact_phone text, -- E.164
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER franchisee_orgs_updated_at
  BEFORE UPDATE ON public.franchisee_orgs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Stations
CREATE TABLE public.stations (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code              text NOT NULL UNIQUE, -- e.g. 31-NBO-001
  name              text NOT NULL,
  slug              text NOT NULL UNIQUE,
  town_id           uuid NOT NULL REFERENCES public.towns(id) ON DELETE RESTRICT,
  county_id         uuid NOT NULL REFERENCES public.counties(id) ON DELETE RESTRICT,
  region_id         uuid NOT NULL REFERENCES public.regions(id) ON DELETE RESTRICT,
  address           text,
  location          geography(Point, 4326),
  phone             text, -- E.164
  whatsapp          text, -- E.164
  email             text,
  hours             jsonb DEFAULT '{}', -- {"mon":{"open":"06:00","close":"22:00"},...}
  is_24h            boolean NOT NULL DEFAULT false,
  status            station_status NOT NULL DEFAULT 'draft',
  operating_model   operating_model NOT NULL DEFAULT 'franchise',
  franchisee_org_id uuid REFERENCES public.franchisee_orgs(id) ON DELETE SET NULL,
  corridor_tags     text[] DEFAULT '{}',
  opened_on         date,
  description       text,
  is_demo           boolean NOT NULL DEFAULT false,
  deleted_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_stations_town ON public.stations(town_id);
CREATE INDEX idx_stations_county ON public.stations(county_id);
CREATE INDEX idx_stations_region ON public.stations(region_id);
CREATE INDEX idx_stations_location ON public.stations USING GIST(location);
CREATE INDEX idx_stations_status ON public.stations(status);
CREATE INDEX idx_stations_slug ON public.stations(slug);
CREATE INDEX idx_stations_corridor ON public.stations USING GIN(corridor_tags);
CREATE INDEX idx_stations_deleted ON public.stations(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER stations_updated_at
  BEFORE UPDATE ON public.stations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Add FK for user_roles.station_id now that stations table exists
ALTER TABLE public.user_roles
  ADD CONSTRAINT fk_user_roles_station
    FOREIGN KEY (station_id) REFERENCES public.stations(id) ON DELETE SET NULL;

CREATE INDEX idx_user_roles_station ON public.user_roles(station_id);

-- Station ↔ Service junction
CREATE TABLE public.station_services (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id  uuid NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  service_id  uuid NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  is_active   boolean NOT NULL DEFAULT true,
  details     jsonb DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (station_id, service_id)
);

CREATE INDEX idx_station_services_station ON public.station_services(station_id);
CREATE INDEX idx_station_services_service ON public.station_services(service_id);

-- Station media (gallery images)
CREATE TABLE public.station_media (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id  uuid NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  url         text NOT NULL,
  alt_text    text NOT NULL DEFAULT '',
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_station_media_station ON public.station_media(station_id);
