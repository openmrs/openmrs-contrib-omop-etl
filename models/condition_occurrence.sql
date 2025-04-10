MODEL (
  name omop_db.CONDITION_OCCURRENCE,
  kind FULL
);

SELECT
    c.condition_id AS condition_occurrence_id,
    c.patient_id AS person_id,
    omrs_to_omop_concept.omop_concept_id AS condition_concept_id,
    DATE(c.onset_date) AS condition_start_date,
    c.onset_date AS condition_start_datetime,
    DATE(c.end_date) AS condition_end_date,
    c.end_date AS condition_end_datetime,
    0 AS condition_type_concept_id,
    0 AS condition_status_concept_id,
    CAST(COALESCE(c.void_reason, '') AS VARCHAR(20)) AS stop_reason,
    NULL AS provider_id,
    NULL AS visit_occurrence_id,
    NULL AS visit_detail_id,
    CAST('' AS VARCHAR(50)) AS condition_source_value,
    omrs_to_omop_concept.omrs_concept_id AS condition_source_concept_id,
    COALESCE(c.verification_status, '') AS condition_status_source_value
FROM openmrs.conditions AS c
         INNER JOIN raw.OMRS_TO_OMOP_CONCEPT omrs_to_omop_concept
                    ON c.condition_coded = omrs_to_omop_concept.omrs_concept_id  AND relationship_id='SAME-AS' AND vocabulary_id='CIEL'
WHERE c.voided = 0;
