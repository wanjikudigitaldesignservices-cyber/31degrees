-- Migration: 00002_enums
-- Purpose: All Postgres enums used across the schema

-- Station status
CREATE TYPE public.station_status AS ENUM (
  'draft', 'published', 'coming_soon', 'temporarily_closed', 'closed'
);

-- Station operating model
CREATE TYPE public.operating_model AS ENUM (
  'franchise', 'company_owned'
);

-- Town tier
CREATE TYPE public.town_tier AS ENUM (
  'hub', 'city', 'town', 'highway'
);

-- Fuel price status
CREATE TYPE public.fuel_price_status AS ENUM (
  'draft', 'published', 'superseded'
);

-- Order status (state machine)
CREATE TYPE public.order_status AS ENUM (
  'pending_payment', 'paid', 'ready_for_pickup', 'collected',
  'failed', 'expired', 'cancelled', 'refunded'
);

-- Payment status
CREATE TYPE public.payment_status AS ENUM (
  'initiated', 'pending', 'completed', 'failed', 'cancelled', 'refunded'
);

-- Franchise application status (state machine)
CREATE TYPE public.franchise_app_status AS ENUM (
  'draft', 'submitted', 'screening', 'interview', 'site_evaluation',
  'due_diligence', 'offer', 'agreement', 'onboarding', 'active',
  'rejected', 'withdrawn'
);

-- Franchise entity type
CREATE TYPE public.franchise_entity_type AS ENUM (
  'individual', 'partnership', 'limited_company', 'other'
);

-- Site ownership
CREATE TYPE public.site_ownership AS ENUM (
  'owned', 'leased', 'none'
);

-- Blog post status
CREATE TYPE public.blog_post_status AS ENUM (
  'draft', 'scheduled', 'published', 'archived'
);

-- Job posting status
CREATE TYPE public.job_posting_status AS ENUM (
  'draft', 'open', 'closed', 'filled'
);

-- Job application status
CREATE TYPE public.job_app_status AS ENUM (
  'received', 'screening', 'shortlisted', 'interview', 'offered', 'hired', 'rejected'
);

-- Support ticket status
CREATE TYPE public.ticket_status AS ENUM (
  'open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'
);

-- Support ticket priority
CREATE TYPE public.ticket_priority AS ENUM (
  'low', 'medium', 'high', 'urgent'
);

-- Contact message topic
CREATE TYPE public.contact_topic AS ENUM (
  'station_feedback', 'franchise', 'fleet', 'careers', 'media', 'shop', 'rewards', 'general'
);

-- Promotion discount type
CREATE TYPE public.discount_type AS ENUM (
  'percent', 'fixed'
);

-- Promotion scope
CREATE TYPE public.promo_scope AS ENUM (
  'all', 'category', 'product'
);

-- Rewards tier
CREATE TYPE public.rewards_tier AS ENUM (
  'bronze', 'silver', 'gold', 'platinum'
);

-- Rewards ledger entry type
CREATE TYPE public.ledger_entry_type AS ENUM (
  'earn', 'redeem', 'expire', 'adjustment'
);

-- User role
CREATE TYPE public.app_role AS ENUM (
  'super_admin', 'hq_admin', 'content_editor', 'regional_manager',
  'support_agent', 'station_manager', 'customer'
);

-- Audit action type
CREATE TYPE public.audit_action AS ENUM (
  'INSERT', 'UPDATE', 'DELETE'
);

-- Station update request status
CREATE TYPE public.update_request_status AS ENUM (
  'pending', 'approved', 'rejected'
);

-- Franchise application document type
CREATE TYPE public.franchise_doc_type AS ENUM (
  'id_document', 'kra_pin', 'company_registration',
  'title_deed', 'lease_agreement', 'site_photo',
  'bank_statement', 'business_plan', 'other'
);
