MODEL(
        name omop_db.NOTE,
        kind FULL
);

SELECT o.obs_id                AS note_id,
       o.person_id             AS person_id,
       DATE(o.obs_datetime)    AS note_date,
       o.obs_datetime          AS note_datetime,
       44814645                AS note_type_concept_id,  -- "Note"
       44814645                AS note_class_concept_id, -- "Note"
       CAST('' AS VARCHAR(50)) AS note_title,
       o.value_text            AS note_text,
       4180186                 AS encoding_concept_id,   -- UTF-8
       0                       AS language_concept_id,
       creator.person_id       AS provider_id,
       e.visit_id              AS visit_occurrence_id,
       CAST(NULL AS INTEGER)   AS visit_detail_id,
       CAST('' AS VARCHAR(50)) AS note_source_value,
       CAST(NULL AS BIGINT)    AS note_event_id,
       CAST(NULL AS INTEGER)   AS note_event_field_concept_id
FROM openmrs.obs o
         INNER JOIN openmrs.encounter e ON o.encounter_id = e.encounter_id
         INNER JOIN openmrs.encounter_type et ON e.encounter_type = et.encounter_type_id
         INNER JOIN openmrs.users creator ON o.creator = creator.user_id
WHERE o.voided = 0
  AND et.encounter_type_id = 8 -- 8 = visit note
  AND o.value_text IS NOT NULL;
