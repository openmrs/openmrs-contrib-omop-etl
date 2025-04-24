MODEL(
        name omop_db.PROVIDER,
        kind FULL
);

SELECT u.user_id                                  AS provider_id,
       CONCAT(pn.given_name, ' ', pn.family_name) AS provider_name,
       CAST(NULL AS VARCHAR(20))                  AS npi,
       CAST(NULL AS VARCHAR(20))                  AS dea,
       CAST(NULL AS INTEGER)                      AS specialty_concept_id,
       CAST(NULL AS INTEGER)                      AS care_site_id,
       CAST(YEAR(p.birthdate) AS INTEGER)         AS year_of_birth,
       CASE
           WHEN p.gender = 'M' THEN 8507 -- OMOP concept_id for Male
           WHEN p.gender = 'F' THEN 8532 -- OMOP concept_id for Female
           ELSE 0
           END                                    AS gender_concept_id,
       CAST(u.uuid AS VARCHAR(50))                AS provider_source_value,
       CAST(NULL AS VARCHAR(50))                  AS specialty_source_value,
       CAST(NULL AS INTEGER)                      AS specialty_source_concept_id,
       p.gender                                   AS gender_source_value,
       CASE
           WHEN p.gender = 'M' THEN 8507
           WHEN p.gender = 'F' THEN 8532
           ELSE 0
           END                                    AS gender_source_concept_id
FROM openmrs.users AS u
         INNER JOIN openmrs.person AS p ON u.person_id = p.person_id
         INNER JOIN openmrs.person_name AS pn ON u.person_id = pn.person_id
WHERE u.retired = 0;
