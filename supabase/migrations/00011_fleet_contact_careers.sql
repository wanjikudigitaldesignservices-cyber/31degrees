-- Migration: 00011_fleet_contact_careers
-- Purpose: Fleet enquiries, contact messages, careers postings & applications

-- Fleet enquiries
CREATE TABLE public.fleet_enquiries (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name    text NOT NULL,
  contact_name    text NOT NULL,
  email           text NOT NULL,
  phone           text NOT NULL, -- E.164
  fleet_size      text,
  fuel_volume     text,
  regions_needed  text,
  message         text,
  consent         boolean NOT NULL DEFAULT false,
  consent_at      timestamptz,
  notice_version  text,
  status          text NOT NULL DEFAULT 'new',
  assigned_to     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_fleet_enquiries_status ON public.fleet_enquiries(status);

CREATE TRIGGER fleet_enquiries_updated_at
  BEFORE UPDATE ON public.fleet_enquiries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Contact messages
CREATE TABLE public.contact_messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic           contact_topic NOT NULL DEFAULT 'general',
  full_name       text NOT NULL,
  email           text NOT NULL,
  phone           text,
  station_id      uuid REFERENCES public.stations(id) ON DELETE SET NULL,
  subject         text,
  message         text NOT NULL,
  consent         boolean NOT NULL DEFAULT false,
  consent_at      timestamptz,
  notice_version  text,
  status          text NOT NULL DEFAULT 'new',
  assigned_to     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_contact_messages_topic ON public.contact_messages(topic);
CREATE INDEX idx_contact_messages_status ON public.contact_messages(status);

CREATE TRIGGER contact_messages_updated_at
  BEFORE UPDATE ON public.contact_messages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Job postings
CREATE TABLE public.job_postings (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title           text NOT NULL,
  slug            text NOT NULL UNIQUE,
  department      text,
  location        text,      -- e.g. "Nairobi", "Mombasa", "Any 31° Station"
  type            text,      -- 'full_time', 'part_time', 'contract'
  description     text NOT NULL, -- rich text
  requirements    text,         -- rich text
  benefits        text,         -- rich text
  status          job_posting_status NOT NULL DEFAULT 'draft',
  opens_at        date,
  closes_at       date,
  seo_title       text,
  seo_description text,
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_job_postings_status ON public.job_postings(status);
CREATE INDEX idx_job_postings_slug ON public.job_postings(slug);

CREATE TRIGGER job_postings_updated_at
  BEFORE UPDATE ON public.job_postings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Job applications
CREATE TABLE public.job_applications (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id          uuid NOT NULL REFERENCES public.job_postings(id) ON DELETE CASCADE,
  full_name       text NOT NULL,
  email           text NOT NULL,
  phone           text NOT NULL, -- E.164
  cv_path         text,          -- storage path (private-docs bucket)
  cover_letter    text,
  status          job_app_status NOT NULL DEFAULT 'received',
  consent         boolean NOT NULL DEFAULT false,
  consent_at      timestamptz,
  notice_version  text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_job_applications_job ON public.job_applications(job_id);
CREATE INDEX idx_job_applications_status ON public.job_applications(status);

CREATE TRIGGER job_applications_updated_at
  BEFORE UPDATE ON public.job_applications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
