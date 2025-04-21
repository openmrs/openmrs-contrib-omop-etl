MODEL (
  name omop_db.CONCEPT_SYNONYM,
  kind SEED (
    path '$root/seed/CONCEPT_SYNONYM.csv',
    csv_settings (
      delimiter = "\t"
    )
  )
);
