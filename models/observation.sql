MODEL(
        name omop_db.OBSERVATION,
        kind FULL
);

SELECT o.obs_id                                              AS observation_id,
       o.person_id                                           AS person_id,
       CAST(omrs_to_omop_concept.omop_concept_id AS INT)     AS observation_concept_id,
       DATE(o.obs_datetime)                                  AS observation_date,
       o.obs_datetime                                        AS observation_datetime,
       32827                                                 AS observation_type_concept_id, -- EHR encounter record
       CAST(o.value_numeric AS NUMERIC)                      AS value_as_number,
       LEFT(o.value_text, 60)                                AS value_as_string,
       CAST(value_concept_map.omop_concept_id AS INT)        AS value_as_concept_id,
       CAST(NULL AS INTEGER)                                 AS qualifier_concept_id,
       CAST(NULL AS INTEGER)                                 AS unit_concept_id,
       creator.person_id                                     AS provider_id,
       e.visit_id                                            AS visit_occurrence_id,
       CAST(NULL AS INTEGER)                                 AS visit_detail_id,
       CAST('' AS VARCHAR(50))                               AS observation_source_value,
       CAST(omrs_to_omop_concept.omop_concept_id AS INTEGER) AS observation_source_concept_id,
       cn.units                                              AS unit_source_value,
       CAST('' AS VARCHAR(50))                               AS qualifier_source_value,
       CAST(o.value_numeric AS VARCHAR(50))                  AS value_source_value,
       CAST(NULL AS BIGINT)                                  AS observation_event_id,
       CAST(NULL AS INTEGER)                                 AS obs_event_field_concept_id
FROM openmrs.obs AS o
         INNER JOIN openmrs.encounter e ON o.encounter_id = e.encounter_id
         INNER JOIN openmrs.encounter_type ON e.encounter_type = encounter_type.encounter_type_id
         LEFT JOIN openmrs.concept_numeric cn ON o.concept_id = cn.concept_id
    AND encounter_type_id NOT IN (5, 8, 11)
         INNER JOIN raw.OMRS_TO_OMOP_CONCEPT omrs_to_omop_concept
                    ON o.concept_id = omrs_to_omop_concept.omrs_concept_id
                        AND relationship_id = 'SAME-AS'
                        AND vocabulary_id = 'CIEL'
         INNER JOIN openmrs.users creator ON o.creator = creator.user_id
         LEFT JOIN raw.OMRS_TO_OMOP_CONCEPT value_concept_map
                   ON o.value_coded = value_concept_map.omrs_concept_id
                       AND value_concept_map.relationship_id = 'SAME-AS'
                       AND value_concept_map.vocabulary_id = 'CIEL'
WHERE o.voided = 0;
