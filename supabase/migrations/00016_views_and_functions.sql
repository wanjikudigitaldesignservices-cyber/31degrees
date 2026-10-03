-- Migration: 00016_views_and_functions
-- Purpose: Public views and PostGIS functions for station search

-- Public stations view (safe columns only)
CREATE OR REPLACE VIEW public.public_stations AS
SELECT
  s.id, s.code, s.name, s.slug,
  s.town_id, t.name AS town_name, t.slug AS town_slug,
  s.county_id, c.name AS county_name,
  s.region_id, r.name AS region_name,
  s.address,
  ST_Y(s.location::geometry) AS lat,
  ST_X(s.location::geometry) AS lng,
  s.phone, s.whatsapp, s.email,
  s.hours, s.is_24h,
  s.status,
  s.corridor_tags,
  s.opened_on,
  s.description,
  s.is_demo,
  -- Aggregate services for this station
  COALESCE(
    (SELECT jsonb_agg(jsonb_build_object(
      'id', sv.id, 'name', sv.name, 'slug', sv.slug, 'icon_name', sv.icon_name
    ) ORDER BY sv.sort_order)
    FROM public.station_services ss
    JOIN public.services sv ON sv.id = ss.service_id
    WHERE ss.station_id = s.id AND ss.is_active = true),
    '[]'::jsonb
  ) AS services
FROM public.stations s
JOIN public.towns t ON t.id = s.town_id
JOIN public.counties c ON c.id = s.county_id
JOIN public.regions r ON r.id = s.region_id
WHERE s.status = 'published' AND s.deleted_at IS NULL;

-- Nearest stations by lat/lng using PostGIS
CREATE OR REPLACE FUNCTION public.nearest_stations(
  _lat double precision,
  _lng double precision,
  _limit int DEFAULT 10,
  _radius_km double precision DEFAULT 50.0
)
RETURNS TABLE (
  id uuid,
  code text,
  name text,
  slug text,
  town_name text,
  town_slug text,
  county_name text,
  region_name text,
  address text,
  lat double precision,
  lng double precision,
  phone text,
  whatsapp text,
  is_24h boolean,
  services jsonb,
  distance_km double precision,
  is_demo boolean
) AS $$
  SELECT
    s.id, s.code, s.name, s.slug,
    t.name AS town_name, t.slug AS town_slug,
    c.name AS county_name, r.name AS region_name,
    s.address,
    ST_Y(s.location::geometry) AS lat,
    ST_X(s.location::geometry) AS lng,
    s.phone, s.whatsapp, s.is_24h,
    COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
        'id', sv.id, 'name', sv.name, 'slug', sv.slug
      ))
      FROM public.station_services ss
      JOIN public.services sv ON sv.id = ss.service_id
      WHERE ss.station_id = s.id AND ss.is_active = true),
      '[]'::jsonb
    ) AS services,
    ROUND(
      (ST_Distance(
        s.location,
        ST_SetSRID(ST_MakePoint(_lng, _lat), 4326)::geography
      ) / 1000)::numeric, 1
    )::double precision AS distance_km,
    s.is_demo
  FROM public.stations s
  JOIN public.towns t ON t.id = s.town_id
  JOIN public.counties c ON c.id = s.county_id
  JOIN public.regions r ON r.id = s.region_id
  WHERE s.status = 'published'
    AND s.deleted_at IS NULL
    AND ST_DWithin(
      s.location,
      ST_SetSRID(ST_MakePoint(_lng, _lat), 4326)::geography,
      _radius_km * 1000
    )
  ORDER BY s.location <-> ST_SetSRID(ST_MakePoint(_lng, _lat), 4326)::geography
  LIMIT _limit;
$$ LANGUAGE sql STABLE;

-- Generate order reference
CREATE OR REPLACE FUNCTION public.generate_order_ref()
RETURNS text AS $$
DECLARE
  _ref text;
  _exists boolean;
BEGIN
  LOOP
    _ref := '31D-' || upper(substring(encode(gen_random_bytes(4), 'hex') from 1 for 6));
    SELECT EXISTS(SELECT 1 FROM public.orders WHERE ref = _ref) INTO _exists;
    EXIT WHEN NOT _exists;
  END LOOP;
  RETURN _ref;
END;
$$ LANGUAGE plpgsql;

-- Generate franchise application reference
CREATE OR REPLACE FUNCTION public.generate_franchise_ref()
RETURNS text AS $$
DECLARE
  _ref text;
  _exists boolean;
BEGIN
  LOOP
    _ref := 'FA-' || upper(substring(encode(gen_random_bytes(4), 'hex') from 1 for 6));
    SELECT EXISTS(SELECT 1 FROM public.franchise_applications WHERE ref = _ref) INTO _exists;
    EXIT WHEN NOT _exists;
  END LOOP;
  RETURN _ref;
END;
$$ LANGUAGE plpgsql;

-- Generate support ticket reference
CREATE OR REPLACE FUNCTION public.generate_ticket_ref()
RETURNS text AS $$
DECLARE
  _ref text;
  _exists boolean;
BEGIN
  LOOP
    _ref := 'TK-' || upper(substring(encode(gen_random_bytes(4), 'hex') from 1 for 6));
    SELECT EXISTS(SELECT 1 FROM public.support_tickets WHERE ref = _ref) INTO _exists;
    EXIT WHEN NOT _exists;
  END LOOP;
  RETURN _ref;
END;
$$ LANGUAGE plpgsql;

-- Generate rewards card number
CREATE OR REPLACE FUNCTION public.generate_rewards_card()
RETURNS text AS $$
DECLARE
  _no text;
  _exists boolean;
BEGIN
  LOOP
    _no := '31R-' || upper(substring(encode(gen_random_bytes(4), 'hex') from 1 for 6));
    SELECT EXISTS(SELECT 1 FROM public.rewards_members WHERE card_no = _no) INTO _exists;
    EXIT WHEN NOT _exists;
  END LOOP;
  RETURN _no;
END;
$$ LANGUAGE plpgsql;

-- Town prices with inheritance
CREATE OR REPLACE FUNCTION public.get_town_prices(_town_slug text)
RETURNS TABLE (
  grade_name text,
  grade_slug text,
  color_token text,
  price_kes numeric(12,2),
  effective_from date,
  is_reference boolean,
  reference_town_name text
) AS $$
  WITH target_town AS (
    SELECT id, name, price_reference_town_id FROM public.towns WHERE slug = _town_slug
  ),
  resolved_town AS (
    SELECT
      COALESCE(tt.price_reference_town_id, tt.id) AS price_town_id,
      tt.price_reference_town_id IS NOT NULL AS is_ref,
      ref_t.name AS ref_name
    FROM target_town tt
    LEFT JOIN public.towns ref_t ON ref_t.id = tt.price_reference_town_id
  )
  SELECT DISTINCT ON (fg.sort_order)
    fg.name,
    fg.slug,
    fg.color_token,
    fp.price_kes,
    fp.effective_from,
    rt.is_ref,
    rt.ref_name
  FROM resolved_town rt
  CROSS JOIN public.fuel_grades fg
  LEFT JOIN public.fuel_prices fp ON fp.town_id = rt.price_town_id
    AND fp.grade_id = fg.id
    AND fp.status = 'published'
    AND fp.effective_from <= CURRENT_DATE
  WHERE fg.is_active = true
  ORDER BY fg.sort_order, fp.effective_from DESC;
$$ LANGUAGE sql STABLE;
