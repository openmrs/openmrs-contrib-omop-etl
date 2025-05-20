MODEL (
  name raw.OMRS_CONCEPT,
  kind FULL
);

SELECT c.concept_id,
       c.uuid,
       crt.code AS concept_code,
       crs.name AS vocabulary_id
FROM openmrs.concept c
         INNER JOIN openmrs.concept_reference_map crm
                    ON c.concept_id = crm.concept_id
         INNER JOIN openmrs.concept_reference_term crt
                    ON crm.concept_reference_term_id = crt.concept_reference_term_id
         INNER JOIN openmrs.concept_reference_source crs
                    ON crs.concept_source_id = crt.concept_source_id
