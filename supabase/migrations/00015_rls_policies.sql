-- Migration: 00015_rls_policies
-- Purpose: Enable RLS on EVERY public table and create policies
-- Principle: deny by default. No policy = no access.

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.counties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.towns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchisee_orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuel_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuel_price_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_application_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_application_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.testimonials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchisee_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.station_update_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES
-- ============================================================
-- Users can read their own profile
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT USING (id = auth.uid());

-- Admins can read all profiles
CREATE POLICY profiles_select_admin ON public.profiles
  FOR SELECT USING (private.is_admin());

-- Users can update their own profile
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- Admins can update profiles
CREATE POLICY profiles_update_admin ON public.profiles
  FOR UPDATE USING (private.has_role('super_admin'));

-- ============================================================
-- USER_ROLES
-- ============================================================
-- Users can see their own roles
CREATE POLICY user_roles_select_own ON public.user_roles
  FOR SELECT USING (user_id = auth.uid());

-- super_admin and hq_admin can see all roles
CREATE POLICY user_roles_select_admin ON public.user_roles
  FOR SELECT USING (private.has_role('super_admin') OR private.has_role('hq_admin'));

-- Only super_admin can manage roles
CREATE POLICY user_roles_insert_admin ON public.user_roles
  FOR INSERT WITH CHECK (private.has_role('super_admin'));

CREATE POLICY user_roles_update_admin ON public.user_roles
  FOR UPDATE USING (private.has_role('super_admin'));

CREATE POLICY user_roles_delete_admin ON public.user_roles
  FOR DELETE USING (private.has_role('super_admin'));

-- ============================================================
-- GEOGRAPHY (regions, counties, towns) — public read
-- ============================================================
CREATE POLICY regions_select_public ON public.regions FOR SELECT USING (true);
CREATE POLICY regions_insert_admin ON public.regions FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY regions_update_admin ON public.regions FOR UPDATE USING (private.is_admin());

CREATE POLICY counties_select_public ON public.counties FOR SELECT USING (true);
CREATE POLICY counties_insert_admin ON public.counties FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY counties_update_admin ON public.counties FOR UPDATE USING (private.is_admin());

CREATE POLICY towns_select_public ON public.towns FOR SELECT USING (true);
CREATE POLICY towns_insert_admin ON public.towns FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY towns_update_admin ON public.towns FOR UPDATE USING (private.is_admin());

-- ============================================================
-- SERVICES — public read
-- ============================================================
CREATE POLICY services_select_public ON public.services FOR SELECT USING (true);
CREATE POLICY services_insert_admin ON public.services FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY services_update_admin ON public.services FOR UPDATE USING (private.is_admin());

-- ============================================================
-- STATIONS — public read only published, non-deleted
-- ============================================================
CREATE POLICY stations_select_public ON public.stations
  FOR SELECT USING (
    (status = 'published' AND deleted_at IS NULL)
    OR private.is_admin()
    OR private.owns_station(id)
  );

CREATE POLICY stations_insert_admin ON public.stations
  FOR INSERT WITH CHECK (private.is_admin());

CREATE POLICY stations_update_admin ON public.stations
  FOR UPDATE USING (
    private.has_role('super_admin') OR private.has_role('hq_admin')
    OR private.in_region(region_id)
    OR private.owns_station(id)
  );

CREATE POLICY stations_delete_admin ON public.stations
  FOR DELETE USING (private.has_role('super_admin'));

-- Station services and media — public read for published stations
CREATE POLICY station_services_select ON public.station_services FOR SELECT USING (true);
CREATE POLICY station_services_insert ON public.station_services FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY station_services_update ON public.station_services FOR UPDATE USING (private.is_admin());
CREATE POLICY station_services_delete ON public.station_services FOR DELETE USING (private.is_admin());

CREATE POLICY station_media_select ON public.station_media FOR SELECT USING (true);
CREATE POLICY station_media_insert ON public.station_media FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY station_media_update ON public.station_media FOR UPDATE USING (private.is_admin());
CREATE POLICY station_media_delete ON public.station_media FOR DELETE USING (private.is_admin());

-- ============================================================
-- FRANCHISEE_ORGS — admin only
-- ============================================================
CREATE POLICY franchisee_orgs_select ON public.franchisee_orgs
  FOR SELECT USING (private.is_admin());
CREATE POLICY franchisee_orgs_insert ON public.franchisee_orgs
  FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY franchisee_orgs_update ON public.franchisee_orgs
  FOR UPDATE USING (private.is_admin());

-- ============================================================
-- FUEL GRADES — public read
-- ============================================================
CREATE POLICY fuel_grades_select ON public.fuel_grades FOR SELECT USING (true);
CREATE POLICY fuel_grades_insert ON public.fuel_grades FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY fuel_grades_update ON public.fuel_grades FOR UPDATE USING (private.is_admin());

-- ============================================================
-- FUEL PRICES — public read only published non-demo
-- ============================================================
CREATE POLICY fuel_prices_select_public ON public.fuel_prices
  FOR SELECT USING (
    (status = 'published' AND is_demo = false)
    OR private.is_admin()
  );

CREATE POLICY fuel_prices_insert_admin ON public.fuel_prices
  FOR INSERT WITH CHECK (private.is_admin());

CREATE POLICY fuel_prices_update_admin ON public.fuel_prices
  FOR UPDATE USING (private.is_admin());

CREATE POLICY fuel_price_batches_select ON public.fuel_price_batches
  FOR SELECT USING (private.is_admin());
CREATE POLICY fuel_price_batches_insert ON public.fuel_price_batches
  FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY fuel_price_batches_update ON public.fuel_price_batches
  FOR UPDATE USING (private.is_admin());

-- ============================================================
-- SHOP (products, variants, media, inventory, promotions)
-- ============================================================
-- Products: public read active non-deleted
CREATE POLICY products_select_public ON public.products
  FOR SELECT USING (
    (is_active AND deleted_at IS NULL)
    OR private.is_admin()
  );
CREATE POLICY products_insert_admin ON public.products FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY products_update_admin ON public.products FOR UPDATE USING (private.is_admin());
CREATE POLICY products_delete_admin ON public.products FOR DELETE USING (private.has_role('super_admin'));

CREATE POLICY product_categories_select ON public.product_categories FOR SELECT USING (true);
CREATE POLICY product_categories_insert ON public.product_categories FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY product_categories_update ON public.product_categories FOR UPDATE USING (private.is_admin());

CREATE POLICY product_variants_select ON public.product_variants FOR SELECT USING (true);
CREATE POLICY product_variants_insert ON public.product_variants FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY product_variants_update ON public.product_variants FOR UPDATE USING (private.is_admin());

CREATE POLICY product_media_select ON public.product_media FOR SELECT USING (true);
CREATE POLICY product_media_insert ON public.product_media FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY product_media_delete ON public.product_media FOR DELETE USING (private.is_admin());

-- Inventory: public can read qty for stock display; admin manages
CREATE POLICY inventory_select ON public.inventory FOR SELECT USING (true);
CREATE POLICY inventory_insert ON public.inventory FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY inventory_update ON public.inventory FOR UPDATE USING (private.is_admin() OR private.owns_station(station_id));

-- Promotions: public can read active ones; admin manages
CREATE POLICY promotions_select_public ON public.promotions
  FOR SELECT USING (
    (is_active AND deleted_at IS NULL AND starts_at <= now() AND (ends_at IS NULL OR ends_at > now()))
    OR private.is_admin()
  );
CREATE POLICY promotions_insert_admin ON public.promotions FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY promotions_update_admin ON public.promotions FOR UPDATE USING (private.is_admin());
CREATE POLICY promotions_delete_admin ON public.promotions FOR DELETE USING (private.has_role('super_admin'));

-- ============================================================
-- ORDERS — owner + admin
-- ============================================================
CREATE POLICY orders_select ON public.orders
  FOR SELECT USING (
    user_id = auth.uid()
    OR private.is_admin()
    OR private.owns_station(pickup_station_id)
  );

-- Orders created through API (service role), not direct insert
CREATE POLICY orders_insert ON public.orders
  FOR INSERT WITH CHECK (false); -- only via service role

CREATE POLICY orders_update ON public.orders
  FOR UPDATE USING (
    private.is_admin()
    OR private.owns_station(pickup_station_id)
  );

CREATE POLICY order_items_select ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
      AND (o.user_id = auth.uid() OR private.is_admin() OR private.owns_station(o.pickup_station_id))
    )
  );

CREATE POLICY order_items_insert ON public.order_items
  FOR INSERT WITH CHECK (false); -- only via service role

-- ============================================================
-- PAYMENTS — owner + admin
-- ============================================================
CREATE POLICY payments_select ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
      AND (o.user_id = auth.uid() OR private.is_admin())
    )
  );

CREATE POLICY payments_insert ON public.payments FOR INSERT WITH CHECK (false); -- service role
CREATE POLICY payments_update ON public.payments FOR UPDATE USING (false); -- service role

-- ============================================================
-- WEBHOOK EVENTS — service role only (no direct access)
-- ============================================================
CREATE POLICY webhook_events_select ON public.webhook_events FOR SELECT USING (private.has_role('super_admin'));
CREATE POLICY webhook_events_insert ON public.webhook_events FOR INSERT WITH CHECK (false); -- service role

-- ============================================================
-- REWARDS — owner + admin
-- ============================================================
CREATE POLICY rewards_members_select_own ON public.rewards_members
  FOR SELECT USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY rewards_members_insert ON public.rewards_members
  FOR INSERT WITH CHECK (false); -- via API only
CREATE POLICY rewards_members_update ON public.rewards_members
  FOR UPDATE USING (private.is_admin());

CREATE POLICY rewards_ledger_select_own ON public.rewards_ledger
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.rewards_members rm
      WHERE rm.id = member_id AND (rm.user_id = auth.uid() OR private.is_admin())
    )
  );
CREATE POLICY rewards_ledger_insert ON public.rewards_ledger
  FOR INSERT WITH CHECK (false); -- via API only

-- ============================================================
-- FRANCHISE
-- ============================================================
-- Leads: admin only
CREATE POLICY franchise_leads_select ON public.franchise_leads FOR SELECT USING (private.is_admin());
CREATE POLICY franchise_leads_insert ON public.franchise_leads FOR INSERT WITH CHECK (false); -- via API
CREATE POLICY franchise_leads_update ON public.franchise_leads FOR UPDATE USING (private.is_admin());

-- Applications: owner sees own, admin sees all
CREATE POLICY franchise_apps_select ON public.franchise_applications
  FOR SELECT USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY franchise_apps_insert ON public.franchise_applications
  FOR INSERT WITH CHECK (false); -- via API
CREATE POLICY franchise_apps_update ON public.franchise_applications
  FOR UPDATE USING (user_id = auth.uid() OR private.is_admin());

-- Application documents: owner + admin
CREATE POLICY franchise_docs_select ON public.franchise_application_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.franchise_applications fa
      WHERE fa.id = application_id AND (fa.user_id = auth.uid() OR private.is_admin())
    )
  );
CREATE POLICY franchise_docs_insert ON public.franchise_application_documents
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.franchise_applications fa
      WHERE fa.id = application_id AND fa.user_id = auth.uid()
    )
  );

-- Application events: owner sees (timeline), admin manages
CREATE POLICY franchise_events_select ON public.franchise_application_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.franchise_applications fa
      WHERE fa.id = application_id AND (fa.user_id = auth.uid() OR private.is_admin())
    )
  );
CREATE POLICY franchise_events_insert ON public.franchise_application_events
  FOR INSERT WITH CHECK (private.is_admin());

-- Internal notes: admin only
CREATE POLICY franchise_notes_select ON public.franchise_notes
  FOR SELECT USING (private.is_admin());
CREATE POLICY franchise_notes_insert ON public.franchise_notes
  FOR INSERT WITH CHECK (private.is_admin());

-- ============================================================
-- FLEET & CONTACT — via API, admin reads
-- ============================================================
CREATE POLICY fleet_enquiries_select ON public.fleet_enquiries FOR SELECT USING (private.is_admin());
CREATE POLICY fleet_enquiries_insert ON public.fleet_enquiries FOR INSERT WITH CHECK (false); -- via API
CREATE POLICY fleet_enquiries_update ON public.fleet_enquiries FOR UPDATE USING (private.is_admin());

CREATE POLICY contact_messages_select ON public.contact_messages FOR SELECT USING (private.is_admin());
CREATE POLICY contact_messages_insert ON public.contact_messages FOR INSERT WITH CHECK (false); -- via API
CREATE POLICY contact_messages_update ON public.contact_messages FOR UPDATE USING (private.is_admin());

-- ============================================================
-- CAREERS
-- ============================================================
-- Published postings are public
CREATE POLICY job_postings_select ON public.job_postings
  FOR SELECT USING (
    (status = 'open' AND deleted_at IS NULL)
    OR private.is_admin()
  );
CREATE POLICY job_postings_insert ON public.job_postings FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY job_postings_update ON public.job_postings FOR UPDATE USING (private.is_admin());

-- Applications via API only; admin reads
CREATE POLICY job_apps_select ON public.job_applications FOR SELECT USING (private.is_admin());
CREATE POLICY job_apps_insert ON public.job_applications FOR INSERT WITH CHECK (false); -- via API
CREATE POLICY job_apps_update ON public.job_applications FOR UPDATE USING (private.is_admin());

-- ============================================================
-- CONTENT (blog, FAQs, etc.) — public read for published
-- ============================================================
CREATE POLICY blog_categories_select ON public.blog_categories FOR SELECT USING (true);
CREATE POLICY blog_categories_insert ON public.blog_categories FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY blog_categories_update ON public.blog_categories FOR UPDATE USING (private.is_admin());

CREATE POLICY blog_posts_select ON public.blog_posts
  FOR SELECT USING (
    (status = 'published' AND deleted_at IS NULL)
    OR private.is_admin()
  );
CREATE POLICY blog_posts_insert ON public.blog_posts FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY blog_posts_update ON public.blog_posts FOR UPDATE USING (private.is_admin());
CREATE POLICY blog_posts_delete ON public.blog_posts FOR DELETE USING (private.has_role('super_admin'));

CREATE POLICY media_assets_select ON public.media_assets FOR SELECT USING (private.is_admin());
CREATE POLICY media_assets_insert ON public.media_assets FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY media_assets_update ON public.media_assets FOR UPDATE USING (private.is_admin());
CREATE POLICY media_assets_delete ON public.media_assets FOR DELETE USING (private.is_admin());

CREATE POLICY testimonials_select ON public.testimonials FOR SELECT USING (is_active OR private.is_admin());
CREATE POLICY testimonials_insert ON public.testimonials FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY testimonials_update ON public.testimonials FOR UPDATE USING (private.is_admin());

CREATE POLICY faqs_select ON public.faqs FOR SELECT USING (is_active OR private.is_admin());
CREATE POLICY faqs_insert ON public.faqs FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY faqs_update ON public.faqs FOR UPDATE USING (private.is_admin());

CREATE POLICY announcements_select ON public.announcements
  FOR SELECT USING (
    (is_active AND starts_at <= now() AND (ends_at IS NULL OR ends_at > now()))
    OR private.is_admin()
  );
CREATE POLICY announcements_insert ON public.announcements FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY announcements_update ON public.announcements FOR UPDATE USING (private.is_admin());

CREATE POLICY legal_docs_select ON public.legal_documents FOR SELECT USING (is_current OR private.is_admin());
CREATE POLICY legal_docs_insert ON public.legal_documents FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY legal_docs_update ON public.legal_documents FOR UPDATE USING (private.is_admin());

CREATE POLICY site_settings_select ON public.site_settings FOR SELECT USING (true);
CREATE POLICY site_settings_insert ON public.site_settings FOR INSERT WITH CHECK (private.has_role('super_admin'));
CREATE POLICY site_settings_update ON public.site_settings FOR UPDATE USING (private.has_role('super_admin') OR private.has_role('hq_admin'));

-- ============================================================
-- PORTAL
-- ============================================================
-- Support tickets: own + admin
CREATE POLICY tickets_select ON public.support_tickets
  FOR SELECT USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY tickets_insert ON public.support_tickets
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY tickets_update ON public.support_tickets
  FOR UPDATE USING (user_id = auth.uid() OR private.is_admin());

CREATE POLICY ticket_messages_select ON public.ticket_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets st
      WHERE st.id = ticket_id AND (st.user_id = auth.uid() OR private.is_admin())
    )
    AND (is_internal = false OR private.is_admin())
  );
CREATE POLICY ticket_messages_insert ON public.ticket_messages
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Franchisee documents: franchisees and admin
CREATE POLICY franchisee_docs_select ON public.franchisee_documents
  FOR SELECT USING (
    (is_active AND private.has_any_staff_role())
    OR private.is_admin()
  );
CREATE POLICY franchisee_docs_insert ON public.franchisee_documents
  FOR INSERT WITH CHECK (private.is_admin());
CREATE POLICY franchisee_docs_update ON public.franchisee_documents
  FOR UPDATE USING (private.is_admin());

-- Station update requests: station manager + admin
CREATE POLICY station_updates_select ON public.station_update_requests
  FOR SELECT USING (requested_by = auth.uid() OR private.is_admin());
CREATE POLICY station_updates_insert ON public.station_update_requests
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY station_updates_update ON public.station_update_requests
  FOR UPDATE USING (private.is_admin());

-- ============================================================
-- AUDIT LOGS — super_admin read only (append-only enforced by triggers)
-- ============================================================
CREATE POLICY audit_logs_select ON public.audit_logs
  FOR SELECT USING (private.has_role('super_admin') OR private.has_role('hq_admin'));
-- INSERT is done by the audit trigger function (SECURITY DEFINER), not by users directly
CREATE POLICY audit_logs_insert ON public.audit_logs
  FOR INSERT WITH CHECK (false); -- trigger uses SECURITY DEFINER

-- ============================================================
-- RATE LIMITS — no direct user access (used by functions only)
-- ============================================================
CREATE POLICY rate_limits_none ON public.rate_limits
  FOR ALL USING (false); -- managed by rate_limit_check() SECURITY DEFINER
