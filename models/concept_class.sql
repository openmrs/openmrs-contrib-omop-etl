MODEL (
  name omop_db.CONCEPT_CLASS,
  kind SEED (
    path '$root/seed/CONCEPT_CLASS.csv',
    csv_settings (
      delimiter = "\t"
    )
  )
);
