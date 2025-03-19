MODEL (
  name raw.CONCEPT_RELATIONSHIP,
  kind FULL
);

SELECT c.concept_id,
       c.concept_code AS omrs_code,
       MAX(cmt.name)  AS relationship_id,
       crt.code       AS concept_code,
       crs.name       AS vocabulary_id
FROM raw.OMRS_CONCEPT c
         INNER JOIN openmrs.concept_reference_map crm
                    ON c.concept_id = crm.concept_id
         INNER JOIN openmrs.concept_reference_term crt
                    ON crm.concept_reference_term_id = crt.concept_reference_term_id
         INNER JOIN openmrs.concept_reference_source crs
                    ON crs.concept_source_id = crt.concept_source_id
         INNER JOIN openmrs.concept_map_type cmt
                    ON crm.concept_map_type_id = cmt.concept_map_type_id
WHERE crs.name IN ('SNOMED CT',
                   'SNOMED NP',
                   'LOINC',
                   'SNOMED MVP',
                   'CIEL',
                   'ICD-10',
                   'ICD-10-WHO',
                   'ICD-11-WHO',
                   'ICD-10-WHO-2nd',
                   'SNOMED-UK',
                   'SNOMED-US',
                   'RxNORM',
                   'RxNORM Comb'
    )
GROUP BY c.concept_id, crt.code, crs.name;

