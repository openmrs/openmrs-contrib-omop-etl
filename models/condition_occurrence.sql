MODEL (
        name omop_db.CONDITION_OCCURRENCE,
        kind FULL
);

SELECT
    CAST(c.condition_id AS INT) AS condition_occurrence_id,
    CAST(c.patient_id AS INT) AS person_id,
    CAST(omrs_to_omop_concept.omop_concept_id AS INT) AS condition_concept_id,
    DATE(c.onset_date) AS condition_start_date,
    CAST(c.onset_date AS DATETIME) AS condition_start_datetime,
    DATE(c.end_date) AS condition_end_date,
    CAST(c.end_date AS DATETIME) AS condition_end_datetime,
    CAST(0 AS INT) AS condition_type_concept_id,
    CAST(0 AS INT) AS condition_status_concept_id,
    CAST(COALESCE(c.void_reason, '') AS VARCHAR(20)) AS stop_reason,
    CAST(NULL AS INT) AS provider_id,
    CAST(NULL AS INT) AS visit_occurrence_id,
    CAST(NULL AS INT) AS visit_detail_id,
    CAST('' AS VARCHAR(50)) AS condition_source_value,
    CAST(omrs_to_omop_concept.omrs_concept_id AS INT) AS condition_source_concept_id,
    CAST(COALESCE(c.verification_status, '') AS VARCHAR(50)) AS condition_status_source_value
FROM openmrs.conditions AS c
         INNER JOIN raw.OMRS_TO_OMOP_CONCEPT omrs_to_omop_concept
                    ON c.condition_coded = omrs_to_omop_concept.omrs_concept_id
                        AND relationship_id = 'SAME-AS'
                        AND vocabulary_id = 'CIEL'
WHERE c.voided = 0 AND c.onset_date IS NOT NULL;
