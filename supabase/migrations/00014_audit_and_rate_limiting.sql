-- Migration: 00014_audit_and_rate_limiting
-- Purpose: Append-only audit log and rate limiting table

-- Audit logs (APPEND ONLY — no UPDATE or DELETE allowed for any role)
CREATE TABLE public.audit_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    uuid,  -- auth.uid() at time of action, null for system/cron
  actor_role  text,
  table_name  text NOT NULL,
  record_id   uuid,
  action      audit_action NOT NULL,
  old_data    jsonb,
  new_data    jsonb,
  ip_address  inet,
  user_agent  text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indexes for querying audit history
CREATE INDEX idx_audit_logs_actor ON public.audit_logs(actor_id);
CREATE INDEX idx_audit_logs_table ON public.audit_logs(table_name);
CREATE INDEX idx_audit_logs_record ON public.audit_logs(record_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- Prevent any UPDATE or DELETE on audit_logs
CREATE OR REPLACE FUNCTION public.prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are append-only. UPDATE and DELETE are not permitted.';
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_logs_no_update
  BEFORE UPDATE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modification();

CREATE TRIGGER audit_logs_no_delete
  BEFORE DELETE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modification();

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION public.audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
  _actor_id uuid;
  _actor_role text;
BEGIN
  -- Get current user; may be null for system triggers
  _actor_id := auth.uid();

  -- Try to get the user's primary role
  SELECT role::text INTO _actor_role
  FROM public.user_roles
  WHERE user_id = _actor_id
  ORDER BY
    CASE role
      WHEN 'super_admin' THEN 1
      WHEN 'hq_admin' THEN 2
      WHEN 'regional_manager' THEN 3
      WHEN 'station_manager' THEN 4
      WHEN 'content_editor' THEN 5
      WHEN 'support_agent' THEN 6
      ELSE 7
    END
  LIMIT 1;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_logs (actor_id, actor_role, table_name, record_id, action, new_data)
    VALUES (_actor_id, _actor_role, TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.audit_logs (actor_id, actor_role, table_name, record_id, action, old_data, new_data)
    VALUES (_actor_id, _actor_role, TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO public.audit_logs (actor_id, actor_role, table_name, record_id, action, old_data)
    VALUES (_actor_id, _actor_role, TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Apply audit triggers to key tables
CREATE TRIGGER audit_stations
  AFTER INSERT OR UPDATE OR DELETE ON public.stations
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_fuel_prices
  AFTER INSERT OR UPDATE OR DELETE ON public.fuel_prices
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_products
  AFTER INSERT OR UPDATE OR DELETE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_promotions
  AFTER INSERT OR UPDATE OR DELETE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_orders
  AFTER INSERT OR UPDATE OR DELETE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_franchise_applications
  AFTER INSERT OR UPDATE OR DELETE ON public.franchise_applications
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_user_roles
  AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

CREATE TRIGGER audit_site_settings
  AFTER INSERT OR UPDATE OR DELETE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();

-- Rate limiting table (atomic check via function)
CREATE TABLE public.rate_limits (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key         text NOT NULL,       -- e.g. 'ip:1.2.3.4:contact' or 'user:uuid:stk_push'
  tokens      int NOT NULL DEFAULT 0,
  max_tokens  int NOT NULL,
  refill_rate int NOT NULL,        -- tokens per interval
  refill_interval_seconds int NOT NULL,
  last_refill timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_rate_limits_key ON public.rate_limits(key);

-- Atomic rate-limit check function
-- Returns true if the request is allowed, false if rate-limited
CREATE OR REPLACE FUNCTION public.rate_limit_check(
  _key text,
  _max_tokens int DEFAULT 10,
  _refill_rate int DEFAULT 1,
  _refill_interval_seconds int DEFAULT 60,
  _cost int DEFAULT 1
)
RETURNS boolean AS $$
DECLARE
  _row public.rate_limits%ROWTYPE;
  _elapsed_seconds numeric;
  _new_tokens int;
BEGIN
  -- Upsert the rate limit row
  INSERT INTO public.rate_limits (key, tokens, max_tokens, refill_rate, refill_interval_seconds, last_refill)
  VALUES (_key, _max_tokens - _cost, _max_tokens, _refill_rate, _refill_interval_seconds, now())
  ON CONFLICT (key) DO UPDATE SET
    tokens = LEAST(
      public.rate_limits.max_tokens,
      public.rate_limits.tokens + (
        FLOOR(
          EXTRACT(EPOCH FROM (now() - public.rate_limits.last_refill)) / public.rate_limits.refill_interval_seconds
        ) * public.rate_limits.refill_rate
      )::int
    ) - _cost,
    last_refill = CASE
      WHEN EXTRACT(EPOCH FROM (now() - public.rate_limits.last_refill)) >= public.rate_limits.refill_interval_seconds
      THEN now()
      ELSE public.rate_limits.last_refill
    END
  RETURNING * INTO _row;

  RETURN _row.tokens >= 0;
END;
$$ LANGUAGE plpgsql;
