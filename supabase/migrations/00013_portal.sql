-- Migration: 00013_portal
-- Purpose: Franchisee portal — support tickets, franchisee documents, station update requests

-- Support tickets
CREATE TABLE public.support_tickets (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ref             text NOT NULL UNIQUE, -- e.g. TK-XXXXXX
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  station_id      uuid REFERENCES public.stations(id) ON DELETE SET NULL,
  subject         text NOT NULL,
  category        text NOT NULL DEFAULT 'general',
  priority        ticket_priority NOT NULL DEFAULT 'medium',
  status          ticket_status NOT NULL DEFAULT 'open',
  assigned_to     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at     timestamptz,
  closed_at       timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_station ON public.support_tickets(station_id);
CREATE INDEX idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX idx_support_tickets_assigned ON public.support_tickets(assigned_to);

CREATE TRIGGER support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Ticket messages (conversation thread)
CREATE TABLE public.ticket_messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  author_id   uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  content     text NOT NULL,
  is_internal boolean NOT NULL DEFAULT false, -- internal staff notes
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ticket_messages_ticket ON public.ticket_messages(ticket_id);

-- Franchisee documents (shared docs from HQ)
CREATE TABLE public.franchisee_documents (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  description text,
  file_path   text NOT NULL,
  file_name   text NOT NULL,
  category    text NOT NULL DEFAULT 'operations', -- 'operations', 'marketing', 'compliance', 'training'
  audience    text NOT NULL DEFAULT 'all', -- 'all', 'franchise', 'company_owned'
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_franchisee_docs_category ON public.franchisee_documents(category);

CREATE TRIGGER franchisee_documents_updated_at
  BEFORE UPDATE ON public.franchisee_documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Station update requests (portal → admin approval)
CREATE TABLE public.station_update_requests (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id      uuid NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  requested_by    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  field_name      text NOT NULL, -- which field they want to change
  current_value   text,
  requested_value text NOT NULL,
  status          update_request_status NOT NULL DEFAULT 'pending',
  reviewed_by     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at     timestamptz,
  review_note     text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_station_updates_station ON public.station_update_requests(station_id);
CREATE INDEX idx_station_updates_status ON public.station_update_requests(status);

CREATE TRIGGER station_update_requests_updated_at
  BEFORE UPDATE ON public.station_update_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
