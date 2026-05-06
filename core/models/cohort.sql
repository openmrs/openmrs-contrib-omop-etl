MODEL(
        name omop_db.COHORT,
        kind FULL,
        columns(
                cohort_definition_id INT NOT NULL,
                subject_id INT NOT NULL,
                cohort_start_date DATE NOT NULL,
                cohort_end_date DATE NOT NULL
        )
);

SELECT cm.cohort_id                                         AS cohort_definition_id,
       cm.patient_id                                        AS subject_id,
       COALESCE(DATE(cm.start_date), DATE(cm.date_created)) AS cohort_start_date,
       COALESCE(DATE(cm.end_date), CURRENT_DATE)            AS cohort_end_date
FROM openmrs.cohort_member AS cm
WHERE cm.voided = 0;
