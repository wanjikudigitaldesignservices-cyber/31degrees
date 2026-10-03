-- Migration: 00007_fuel_pricing
-- Purpose: Fuel grades and the per-town pricing model with batch publish

CREATE TABLE public.fuel_grades (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE, -- '31° Unleaded', '31° Premium', '31° Diesel'
  slug        text NOT NULL UNIQUE,
  color_token text NOT NULL,        -- 'frost', 'solar', 'graphite'
  sort_order  int NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER fuel_grades_updated_at
  BEFORE UPDATE ON public.fuel_grades
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Fuel price batches for atomic publish/rollback
CREATE TABLE public.fuel_price_batches (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note          text,
  published_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  published_at  timestamptz,
  rolled_back   boolean NOT NULL DEFAULT false,
  rolled_back_at timestamptz,
  rolled_back_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Individual fuel prices per town per grade
CREATE TABLE public.fuel_prices (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  town_id         uuid NOT NULL REFERENCES public.towns(id) ON DELETE RESTRICT,
  grade_id        uuid NOT NULL REFERENCES public.fuel_grades(id) ON DELETE RESTRICT,
  price_kes       numeric(12,2) NOT NULL CHECK (price_kes > 0),
  effective_from  date NOT NULL,
  status          fuel_price_status NOT NULL DEFAULT 'draft',
  batch_id        uuid REFERENCES public.fuel_price_batches(id) ON DELETE SET NULL,
  published_by    uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  published_at    timestamptz,
  note            text,
  is_demo         boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (town_id, grade_id, effective_from)
);

CREATE INDEX idx_fuel_prices_town ON public.fuel_prices(town_id);
CREATE INDEX idx_fuel_prices_grade ON public.fuel_prices(grade_id);
CREATE INDEX idx_fuel_prices_status ON public.fuel_prices(status);
CREATE INDEX idx_fuel_prices_effective ON public.fuel_prices(effective_from DESC);
CREATE INDEX idx_fuel_prices_batch ON public.fuel_prices(batch_id);

CREATE TRIGGER fuel_prices_updated_at
  BEFORE UPDATE ON public.fuel_prices
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- View: current published prices (latest effective_from <= today for each town+grade)
CREATE OR REPLACE VIEW public.current_fuel_prices AS
SELECT DISTINCT ON (fp.town_id, fp.grade_id)
  fp.id,
  fp.town_id,
  t.name AS town_name,
  t.slug AS town_slug,
  t.region_id,
  r.name AS region_name,
  fp.grade_id,
  fg.name AS grade_name,
  fg.slug AS grade_slug,
  fg.color_token,
  fp.price_kes,
  fp.effective_from,
  fp.published_at,
  fp.is_demo,
  t.price_reference_town_id,
  ref_t.name AS reference_town_name
FROM public.fuel_prices fp
JOIN public.towns t ON t.id = fp.town_id
JOIN public.regions r ON r.id = t.region_id
JOIN public.fuel_grades fg ON fg.id = fp.grade_id
LEFT JOIN public.towns ref_t ON ref_t.id = t.price_reference_town_id
WHERE fp.status = 'published'
  AND fp.effective_from <= CURRENT_DATE
ORDER BY fp.town_id, fp.grade_id, fp.effective_from DESC;
