MODEL(
        name omop_db.CARE_SITE,
        kind FULL
);

SELECT l.location_id             AS care_site_id,
       l.name                    AS care_site_name,
       CAST(NULL AS INTEGER)     AS place_of_service_concept_id,
       l.location_id             AS location_id,
       l.name                    AS care_site_source_value,
       CAST(NULL AS VARCHAR(50)) AS place_of_service_source_value
FROM openmrs.location AS l
WHERE l.retired = 0;
