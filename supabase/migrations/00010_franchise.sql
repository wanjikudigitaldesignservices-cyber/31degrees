-- Migration: 00010_franchise
-- Purpose: Franchise leads, applications (full state machine), documents, events, notes

-- Franchise leads (prospectus requests)
CREATE TABLE public.franchise_leads (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name   text NOT NULL,
  email       text NOT NULL,
  phone       text NOT NULL, -- E.164
  county_id   uuid REFERENCES public.counties(id) ON DELETE SET NULL,
  town_id     uuid REFERENCES public.towns(id) ON DELETE SET NULL,
  consent     boolean NOT NULL DEFAULT false,
  consent_at  timestamptz,
  notice_version text,
  status      text NOT NULL DEFAULT 'new', -- new, contacted, converted, closed
  notes       text,
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchise_leads_status ON public.franchise_leads(status);

CREATE TRIGGER franchise_leads_updated_at
  BEFORE UPDATE ON public.franchise_leads
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Franchise applications
CREATE TABLE public.franchise_applications (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ref                 text NOT NULL UNIQUE, -- e.g. FA-XXXXXX
  user_id             uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status              franchise_app_status NOT NULL DEFAULT 'draft',

  -- Step 1: Applicant
  applicant_name      text,
  applicant_email     text,
  applicant_phone     text, -- E.164
  applicant_id_type   text, -- 'national_id', 'passport'

  -- Step 2: Entity
  entity_type         franchise_entity_type,
  company_name        text,
  company_reg_no      text,
  kra_pin             text,
  company_address     text,

  -- Step 3: Proposed site
  proposed_county_id  uuid REFERENCES public.counties(id) ON DELETE SET NULL,
  proposed_town_id    uuid REFERENCES public.towns(id) ON DELETE SET NULL,
  site_address        text,
  site_ownership      site_ownership,
  plot_size_sqm       numeric(10,2),
  road_frontage_m     numeric(10,2),
  site_description    text,

  -- Step 4: Capacity & experience
  funding_source      text,
  investment_band     text, -- 'under_10m', '10m_25m', '25m_50m', '50m_100m', 'over_100m' (KES)
  fuel_experience     text,
  retail_experience   text,
  other_businesses    text,
  why_31_degrees      text,
  how_heard           text, -- 'website', 'referral', 'social_media', 'event', 'other'

  -- Step 5: documents (tracked in franchise_application_documents)

  -- Step 6: Consent
  consent_data        boolean NOT NULL DEFAULT false,
  consent_background  boolean NOT NULL DEFAULT false,
  consent_at          timestamptz,
  notice_version      text,

  -- Internal
  assigned_to         uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  score               jsonb DEFAULT '{}',
  submitted_at        timestamptz,
  last_step_completed int DEFAULT 0,

  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchise_apps_ref ON public.franchise_applications(ref);
CREATE INDEX idx_franchise_apps_user ON public.franchise_applications(user_id);
CREATE INDEX idx_franchise_apps_status ON public.franchise_applications(status);
CREATE INDEX idx_franchise_apps_assigned ON public.franchise_applications(assigned_to);

CREATE TRIGGER franchise_applications_updated_at
  BEFORE UPDATE ON public.franchise_applications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Franchise application documents
CREATE TABLE public.franchise_application_documents (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES public.franchise_applications(id) ON DELETE CASCADE,
  doc_type        franchise_doc_type NOT NULL,
  file_path       text NOT NULL, -- storage path (random key in private-docs bucket)
  file_name       text NOT NULL, -- original filename for display
  file_size       int,
  mime_type       text,
  uploaded_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchise_docs_app ON public.franchise_application_documents(application_id);

-- Franchise application events (state machine transitions)
CREATE TABLE public.franchise_application_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES public.franchise_applications(id) ON DELETE CASCADE,
  from_status     franchise_app_status,
  to_status       franchise_app_status NOT NULL,
  changed_by      uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  note            text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchise_events_app ON public.franchise_application_events(application_id);

-- Franchise internal notes (admin only)
CREATE TABLE public.franchise_notes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES public.franchise_applications(id) ON DELETE CASCADE,
  author_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  content         text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchise_notes_app ON public.franchise_notes(application_id);
