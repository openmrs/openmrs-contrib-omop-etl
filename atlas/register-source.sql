-- Registers omop-db as the WebAPI source. Run by the atlas-source-init service
-- AFTER atlas-webapi is healthy.
--
-- Why not at atlasdb startup? WebAPI 2.15.0's Flyway data migrations (V2_8_0_*)
-- iterate over registered sources and UPDATE tables like public.cc_results that
-- only exist after WebAPI runtime activity. On a fresh CDM, those UPDATEs fail
-- and WebAPI crashes. By waiting until WebAPI completes its initial Flyway
-- pass with zero sources, those migrations are recorded as successful (no-op)
-- and subsequent restarts skip them.

INSERT INTO webapi.source(source_id, source_name, source_key, source_connection, source_dialect)
VALUES (1, 'OpenMRS OMOP', 'OPENMRS_OMOP',
  'jdbc:postgresql://omop-db:5432/omop?user=omop&password=omop', 'postgresql')
ON CONFLICT (source_id) DO NOTHING;

-- daimon_type: 0=CDM, 1=Vocabulary, 2=Results. Priorities from Broadsea.
-- All three target `public` because in this repo the CDM, vocabulary, and
-- Achilles results all live in the same schema.
INSERT INTO webapi.source_daimon(source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES
  (1, 1, 0, 'public', 0),
  (2, 1, 1, 'public', 10),
  (3, 1, 2, 'public', 0)
ON CONFLICT (source_daimon_id) DO NOTHING;
