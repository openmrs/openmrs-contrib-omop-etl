MODEL(
        name omop_db.OBSERVATION,
        kind FULL,
        columns(
                observation_id INT NOT NULL,
                person_id INT NOT NULL,
                observation_concept_id INT NOT NULL,
                observation_date DATE NOT NULL,
                observation_datetime TIMESTAMP,
                observation_type_concept_id INT NOT NULL,
                value_as_number NUMERIC,
                value_as_string VARCHAR(60),
                value_as_concept_id INT,
                qualifier_concept_id INT,
                unit_concept_id INT,
                provider_id INT,
                visit_occurrence_id INT,
                visit_detail_id INT,
                observation_source_value VARCHAR(50),
                observation_source_concept_id INT,
                unit_source_value VARCHAR(50),
                qualifier_source_value VARCHAR(50),
                value_source_value VARCHAR(50),
                observation_event_id BIGINT,
                obs_event_field_concept_id INT
        )
);

SELECT o.obs_id                             AS observation_id,
       o.person_id                          AS person_id,
       omrs_to_omop_concept.omop_concept_id AS observation_concept_id,
       DATE(o.obs_datetime)                 AS observation_date,
       o.obs_datetime                       AS observation_datetime,
       32827                                AS observation_type_concept_id, -- EHR encounter record
       o.value_numeric                      AS value_as_number,
       LEFT(o.value_text, 60)               AS value_as_string,
       value_concept_map.omop_concept_id    AS value_as_concept_id,
       NULL                                 AS qualifier_concept_id,
       NULL                                 AS unit_concept_id,
       creator.person_id                    AS provider_id,
       e.visit_id                           AS visit_occurrence_id,
       NULL                                 AS visit_detail_id,
       ''                                   AS observation_source_value,
       omrs_to_omop_concept.omop_concept_id AS observation_source_concept_id,
       cn.units                             AS unit_source_value,
       ''                                   AS qualifier_source_value,
       o.value_numeric                      AS value_source_value,
       NULL                                 AS observation_event_id,
       NULL                                 AS obs_event_field_concept_id
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
