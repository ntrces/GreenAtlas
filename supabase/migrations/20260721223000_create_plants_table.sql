-- Migration: Create public.plants table with audit triggers and temperature constraints

CREATE TABLE IF NOT EXISTS public.plants (
  id uuid not null default gen_random_uuid (),
  common_name text not null,
  category text null,
  location_zone text null,
  conservation_status text null,
  image_url text null,
  ar_model_url text null,
  created_at timestamp with time zone null default now(),
  description text null,
  scientific_name text null,
  height text null,
  leaf_type text null,
  flowering text null,
  growth text null,
  kingdom text null,
  family text null,
  genus text null,
  species text null,
  ecosystem_type text null,
  ecological_importance text null,
  status text null default 'DRAFT'::text,
  source text null,
  temp_min integer null default 20,
  temp_max integer null default 32,
  constraint plants_pkey primary key (id),
  constraint plants_status_check check (
    (
      status = any (
        array[
          'PUBLISHED'::text,
          'DRAFT'::text,
          'ARCHIVED'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

-- Create audit trigger to log activity
CREATE OR REPLACE TRIGGER plants_audit_trigger
AFTER INSERT OR DELETE OR UPDATE ON public.plants
FOR EACH ROW
EXECUTE FUNCTION log_plant_activity();
