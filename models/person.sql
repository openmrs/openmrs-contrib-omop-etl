MODEL (
  name omop_db.PERSON,
  kind FULL
);

SELECT
    p.patient_id AS person_id,
    CASE
        WHEN per.gender = 'M' THEN 8507 -- OMOP concept_id for Male
        WHEN per.gender = 'F' THEN 8532 -- OMOP concept_id for Female
        ELSE 0
        END AS gender_concept_id,
    CAST(YEAR(per.birthdate) AS INTEGER) AS year_of_birth,
    CAST(MONTH(per.birthdate) AS INTEGER) AS month_of_birth,
    CAST(DAY(per.birthdate) AS INTEGER) AS day_of_birth,
    CAST(per.birthdate AS TIMESTAMP) AS birth_datetime,
    0 AS race_concept_id,
    0 AS ethnicity_concept_id,
    0 AS location_id,
    0 AS provider_id,
    0 AS care_site_id,
    CAST('' AS VARCHAR(50)) AS person_source_value,
    per.gender AS gender_source_value,
    0 AS gender_source_concept_id,
    CAST('' AS VARCHAR(50)) AS race_source_value,
    0 AS race_source_concept_id,
    CAST('' AS VARCHAR(50)) AS ethnicity_source_value,
    0 AS ethnicity_source_concept_id
FROM openmrs.patient AS p
         INNER JOIN openmrs.person AS per ON p.patient_id = per.person_id;
