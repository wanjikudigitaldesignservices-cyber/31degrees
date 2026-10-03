-- Migration: 00001_extensions_and_schemas
-- Purpose: Enable required Postgres extensions and create private schema for helpers
-- Reversible: DROP EXTENSION / DROP SCHEMA

-- Extensions
CREATE EXTENSION IF NOT EXISTS "postgis" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pg_cron" SCHEMA pg_catalog;

-- Private schema for security-definer helper functions (not exposed via PostgREST)
CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO postgres, service_role;

-- Updated-at trigger function (reused on every table)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
