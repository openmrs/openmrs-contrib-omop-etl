MODEL(
        name omop_db.VISIT_OCCURRENCE,
        kind FULL
);

SELECT v.visit_id                                   AS visit_occurrence_id,
       v.patient_id                                 AS person_id,
       0                                            AS visit_concept_id,
       DATE(v.date_started)                         AS visit_start_date,
       v.date_started                               AS visit_start_datetime,
       COALESCE(DATE(v.date_stopped), CURRENT_DATE) AS visit_end_date,        -- revisit this
       COALESCE(v.date_stopped, CURRENT_TIMESTAMP)  AS visit_end_datetime,    -- revisit this
       v.visit_type_id                              AS visit_type_concept_id, -- revisit this
       creator.person_id                            AS provider_id,
       v.location_id                                AS care_site_id,
       CAST('' AS VARCHAR(50))                      AS visit_source_value,
       0                                            AS visit_source_concept_id,
       0                                            AS admitted_from_concept_id,
       CAST('' AS VARCHAR(50))                      AS admitted_from_source_value,
       0                                            AS discharged_to_concept_id,
       CAST('' AS VARCHAR(50))                      AS discharged_to_source_value,
       CAST(NULL AS INTEGER)                        AS preceding_visit_occurrence_id
FROM openmrs.visit AS v
         INNER JOIN openmrs.users AS creator ON v.creator = creator.user_id;
