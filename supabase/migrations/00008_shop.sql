-- Migration: 00008_shop
-- Purpose: Product catalogue, variants, inventory, promotions, orders, payments

-- Product categories
CREATE TABLE public.product_categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  slug        text NOT NULL UNIQUE,
  description text,
  sort_order  int NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER product_categories_updated_at
  BEFORE UPDATE ON public.product_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Products
CREATE TABLE public.products (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  slug          text NOT NULL UNIQUE,
  category_id   uuid REFERENCES public.product_categories(id) ON DELETE SET NULL,
  description   text,
  features      jsonb DEFAULT '[]',
  seo_title     text,
  seo_description text,
  is_active     boolean NOT NULL DEFAULT true,
  sort_order    int NOT NULL DEFAULT 0,
  deleted_at    timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_products_slug ON public.products(slug);
CREATE INDEX idx_products_deleted ON public.products(deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Product variants (e.g. "4L", "1L" for lubricants)
CREATE TABLE public.product_variants (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id          uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sku                 text NOT NULL UNIQUE,
  label               text NOT NULL, -- "4L", "1L", etc.
  price_kes           numeric(12,2) NOT NULL CHECK (price_kes > 0),
  compare_at_price_kes numeric(12,2) CHECK (compare_at_price_kes IS NULL OR compare_at_price_kes > 0),
  weight_grams        int,
  is_active           boolean NOT NULL DEFAULT true,
  sort_order          int NOT NULL DEFAULT 0,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_product_variants_product ON public.product_variants(product_id);

CREATE TRIGGER product_variants_updated_at
  BEFORE UPDATE ON public.product_variants
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Product media
CREATE TABLE public.product_media (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  url         text NOT NULL,
  alt_text    text NOT NULL DEFAULT '',
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_product_media_product ON public.product_media(product_id);

-- Inventory per variant per station
CREATE TABLE public.inventory (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  variant_id    uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
  station_id    uuid NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  qty           int NOT NULL DEFAULT 0 CHECK (qty >= 0),
  reorder_level int NOT NULL DEFAULT 5 CHECK (reorder_level >= 0),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (variant_id, station_id)
);

CREATE INDEX idx_inventory_variant ON public.inventory(variant_id);
CREATE INDEX idx_inventory_station ON public.inventory(station_id);
CREATE INDEX idx_inventory_low_stock ON public.inventory(qty) WHERE qty <= 5; -- for low-stock queries

CREATE TRIGGER inventory_updated_at
  BEFORE UPDATE ON public.inventory
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Promotions / discounts
CREATE TABLE public.promotions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  code            text UNIQUE, -- optional promo code
  discount_type   discount_type NOT NULL,
  discount_value  numeric(12,2) NOT NULL CHECK (discount_value > 0),
  scope           promo_scope NOT NULL DEFAULT 'all',
  scope_ref_id    uuid,       -- category or product ID if scope != 'all'
  min_order_kes   numeric(12,2) DEFAULT 0,
  usage_limit     int,        -- null = unlimited
  used_count      int NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  starts_at       timestamptz NOT NULL,
  ends_at         timestamptz,
  is_active       boolean NOT NULL DEFAULT true,
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_promotions_code ON public.promotions(code) WHERE code IS NOT NULL;
CREATE INDEX idx_promotions_active ON public.promotions(is_active, starts_at, ends_at);

CREATE TRIGGER promotions_updated_at
  BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Orders
CREATE TABLE public.orders (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ref               text NOT NULL UNIQUE, -- human-readable reference e.g. 31D-A1B2C3
  user_id           uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  guest_email       text,
  guest_phone       text,  -- E.164
  guest_name        text,
  status            order_status NOT NULL DEFAULT 'pending_payment',
  pickup_station_id uuid NOT NULL REFERENCES public.stations(id) ON DELETE RESTRICT,
  subtotal_kes      numeric(12,2) NOT NULL CHECK (subtotal_kes >= 0),
  discount_kes      numeric(12,2) NOT NULL DEFAULT 0 CHECK (discount_kes >= 0),
  total_kes         numeric(12,2) NOT NULL CHECK (total_kes >= 0),
  promotion_id      uuid REFERENCES public.promotions(id) ON DELETE SET NULL,
  promo_code_used   text,
  notes             text,
  expires_at        timestamptz,  -- unpaid order expiry
  paid_at           timestamptz,
  collected_at      timestamptz,
  cancelled_at      timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_orders_ref ON public.orders(ref);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_station ON public.orders(pickup_station_id);
CREATE INDEX idx_orders_expires ON public.orders(expires_at) WHERE status = 'pending_payment';

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Order items (snapshot at time of sale)
CREATE TABLE public.order_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  variant_id      uuid REFERENCES public.product_variants(id) ON DELETE SET NULL,
  product_name    text NOT NULL,   -- snapshot
  variant_label   text NOT NULL,   -- snapshot
  sku             text NOT NULL,   -- snapshot
  unit_price_kes  numeric(12,2) NOT NULL CHECK (unit_price_kes > 0),
  qty             int NOT NULL CHECK (qty > 0),
  line_total_kes  numeric(12,2) NOT NULL CHECK (line_total_kes > 0),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_order_items_order ON public.order_items(order_id);

-- Payments
CREATE TABLE public.payments (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id              uuid NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  provider              text NOT NULL DEFAULT 'intasend', -- extensible
  provider_ref          text, -- IntaSend invoice/checkout ID
  mpesa_receipt         text, -- M-Pesa receipt number
  amount_kes            numeric(12,2) NOT NULL CHECK (amount_kes > 0),
  status                payment_status NOT NULL DEFAULT 'initiated',
  phone                 text, -- E.164, the phone that received STK push
  provider_response     jsonb DEFAULT '{}',
  completed_at          timestamptz,
  failed_at             timestamptz,
  failure_reason        text,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_order ON public.payments(order_id);
CREATE INDEX idx_payments_provider_ref ON public.payments(provider_ref);
CREATE INDEX idx_payments_status ON public.payments(status);

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Webhook events (idempotency via event_key)
CREATE TABLE public.webhook_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider        text NOT NULL,
  event_type      text NOT NULL,
  event_key       text NOT NULL UNIQUE, -- provider transaction reference
  payload         jsonb NOT NULL,
  processed       boolean NOT NULL DEFAULT false,
  processed_at    timestamptz,
  error           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_webhook_events_key ON public.webhook_events(event_key);
CREATE INDEX idx_webhook_events_processed ON public.webhook_events(processed);
