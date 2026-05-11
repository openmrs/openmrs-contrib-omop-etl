-- Drop the broadsea-atlasdb image's baked-in Eunomia demo data. Run by the
-- atlasdb-init service after atlasdb is healthy.
--
-- Why this can't live in /docker-entrypoint-initdb.d/: the broadsea-atlasdb
-- image ships with PGDATA already populated. When a fresh named volume mounts,
-- Docker copies the image's contents into it, so Postgres skips initdb scripts
-- on first boot.

DROP SCHEMA IF EXISTS demo_cdm CASCADE;
DROP SCHEMA IF EXISTS demo_cdm_results CASCADE;

-- Clear the image's pre-registered Eunomia source. We register our own source
-- in a later step (atlas-source-init), AFTER WebAPI completes its initial
-- Flyway pass with zero sources — otherwise WebAPI's data migrations
-- (V2_8_0_*) try to UPDATE tables on the source that don't exist yet and crash.
truncate webapi.source;
truncate webapi.source_daimon;
