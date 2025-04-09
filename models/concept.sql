MODEL (
  name raw.OMOP_CONCEPT,
  kind SEED (
    path '$root/seed/CONCEPT.csv',
    csv_settings (
      delimiter = "\t"
    )
  )
);
