MODEL (
  name raw.OMRS_TO_OMOP_CONCEPT,
  kind FULL
);

SELECT
    cr.concept_id AS omrs_concept_id,
    oc.concept_id AS omop_concept_id,
    cr.relationship_id,
    oc.concept_name,
    oc.vocabulary_id,
    oc.domain_id,
    oc.concept_class_id
FROM raw.CONCEPT_RELATIONSHIP cr INNER JOIN  omop_db.CONCEPT oc
                                            ON cr.concept_code = oc.concept_code
