MODEL(
        name omop_db.MEASUREMENT,
        kind FULL
);

SELECT o.obs_id                                                    AS measurement_id,
       o.person_id                                                 AS person_id,
       CAST(omrs_to_omop_concept.omop_concept_id AS INTEGER)       AS measurement_concept_id,
       DATE(o.obs_datetime)                                        AS measurement_date,
       o.obs_datetime                                              AS measurement_datetime,
       CAST(DATE_FORMAT(o.obs_datetime, '%H:%i:%s') AS VARCHAR(8)) AS measurement_time,
       44818701                                                    AS measurement_type_concept_id,
       CAST(NULL AS INTEGER)                                       AS operator_concept_id,
       o.value_numeric                                             AS value_as_number,
       CAST(value_concept_map.omop_concept_id AS INTEGER)          AS value_as_concept_id,
       CAST(NULL AS INTEGER)                                       AS unit_concept_id,
       CAST(cn.low_normal AS NUMERIC)                              AS range_low,
       CAST(cn.hi_normal AS NUMERIC)                               AS range_high,
       creator.person_id                                           AS provider_id,
       e.visit_id                                                  AS visit_occurrence_id,
       CAST(NULL AS INTEGER)                                       AS visit_detail_id,
       CAST('' AS VARCHAR(50))                                     AS measurement_source_value,
       CAST(omrs_to_omop_concept.omop_concept_id AS INTEGER)       AS measurement_source_concept_id,
       cn.units                                                    AS unit_source_value,
       CAST(NULL AS INTEGER)                                       AS unit_source_concept_id,
       CAST(o.value_numeric AS VARCHAR(50))                        AS value_source_value,
       CAST(NULL AS BIGINT)                                        AS measurement_event_id,
       CAST(NULL AS INTEGER)                                       AS meas_event_field_concept_id
FROM openmrs.obs AS o
         INNER JOIN openmrs.encounter e ON o.encounter_id = e.encounter_id
         INNER JOIN openmrs.encounter_type et
                    ON e.encounter_type = et.encounter_type_id AND et.encounter_type_id IN (5, 11)
         LEFT JOIN openmrs.concept_numeric cn ON o.concept_id = cn.concept_id
         INNER JOIN raw.OMRS_TO_OMOP_CONCEPT omrs_to_omop_concept
                    ON o.concept_id = omrs_to_omop_concept.omrs_concept_id
                        AND omrs_to_omop_concept.relationship_id = 'SAME-AS'
                        AND omrs_to_omop_concept.vocabulary_id = 'CIEL'
         LEFT JOIN raw.OMRS_TO_OMOP_CONCEPT value_concept_map
                   ON o.value_coded = value_concept_map.omrs_concept_id
                       AND value_concept_map.relationship_id = 'SAME-AS'
                       AND value_concept_map.vocabulary_id = 'CIEL'
         INNER JOIN openmrs.users creator ON o.creator = creator.user_id
WHERE o.voided = 0;
