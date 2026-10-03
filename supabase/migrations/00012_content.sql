-- Migration: 00012_content
-- Purpose: Blog, media library, testimonials, FAQs, announcements, legal docs, site settings

-- Blog categories
CREATE TABLE public.blog_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  slug        text NOT NULL UNIQUE,
  description text,
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER blog_categories_updated_at
  BEFORE UPDATE ON public.blog_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Blog posts
CREATE TABLE public.blog_posts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title             text NOT NULL,
  slug              text NOT NULL UNIQUE,
  category_id       uuid REFERENCES public.blog_categories(id) ON DELETE SET NULL,
  excerpt           text,
  content           text NOT NULL, -- sanitised HTML from TipTap
  cover_image_url   text,
  cover_image_code  text, -- links to image registry ID e.g. 'N02'
  author_name       text NOT NULL DEFAULT '31° Editorial',
  author_id         uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status            blog_post_status NOT NULL DEFAULT 'draft',
  published_at      timestamptz,
  scheduled_for     timestamptz,
  reading_time_min  int,
  seo_title         text,
  seo_description   text,
  og_image_url      text,
  canonical_url     text,
  deleted_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_blog_posts_slug ON public.blog_posts(slug);
CREATE INDEX idx_blog_posts_category ON public.blog_posts(category_id);
CREATE INDEX idx_blog_posts_status ON public.blog_posts(status);
CREATE INDEX idx_blog_posts_published ON public.blog_posts(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_blog_posts_scheduled ON public.blog_posts(scheduled_for) WHERE status = 'scheduled';

CREATE TRIGGER blog_posts_updated_at
  BEFORE UPDATE ON public.blog_posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Media library
CREATE TABLE public.media_assets (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  url         text NOT NULL,
  filename    text NOT NULL,
  alt_text    text NOT NULL DEFAULT '',
  mime_type   text,
  file_size   int,
  width       int,
  height      int,
  image_code  text, -- optional binding to registry IDs
  usage_count int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_media_assets_code ON public.media_assets(image_code) WHERE image_code IS NOT NULL;

CREATE TRIGGER media_assets_updated_at
  BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Testimonials
CREATE TABLE public.testimonials (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_name text NOT NULL,
  author_role text,
  author_location text,
  content     text NOT NULL,
  rating      int CHECK (rating >= 1 AND rating <= 5),
  is_featured boolean NOT NULL DEFAULT false,
  is_active   boolean NOT NULL DEFAULT true,
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER testimonials_updated_at
  BEFORE UPDATE ON public.testimonials
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- FAQs
CREATE TABLE public.faqs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question    text NOT NULL,
  answer      text NOT NULL,
  category    text NOT NULL DEFAULT 'general', -- 'general', 'franchise', 'fuel', 'shop', 'rewards', 'fleet'
  sort_order  int NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_faqs_category ON public.faqs(category);

CREATE TRIGGER faqs_updated_at
  BEFORE UPDATE ON public.faqs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Announcements (site-wide banner)
CREATE TABLE public.announcements (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  content     text,
  type        text NOT NULL DEFAULT 'info', -- 'info', 'warning', 'promo'
  link_url    text,
  link_text   text,
  starts_at   timestamptz NOT NULL,
  ends_at     timestamptz,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_announcements_active ON public.announcements(is_active, starts_at, ends_at);

CREATE TRIGGER announcements_updated_at
  BEFORE UPDATE ON public.announcements
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Legal documents (versioned)
CREATE TABLE public.legal_documents (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type            text NOT NULL, -- 'privacy', 'terms', 'cookies', 'fuel_quality_pricing'
  title           text NOT NULL,
  slug            text NOT NULL,
  content         text NOT NULL,
  version         text NOT NULL,
  published_at    timestamptz,
  is_current      boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (type, version)
);

CREATE INDEX idx_legal_docs_type ON public.legal_documents(type);
CREATE INDEX idx_legal_docs_current ON public.legal_documents(is_current) WHERE is_current = true;

CREATE TRIGGER legal_documents_updated_at
  BEFORE UPDATE ON public.legal_documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Site settings (key-value, admin-managed)
CREATE TABLE public.site_settings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key         text NOT NULL UNIQUE,
  value       jsonb NOT NULL DEFAULT '{}',
  description text, -- admin helper text
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER site_settings_updated_at
  BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
