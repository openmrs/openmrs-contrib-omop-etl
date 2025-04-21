MODEL (
  name omop_db.VOCABULARY,
  kind SEED (
    path '$root/seed/VOCABULARY.csv',
    csv_settings (
      delimiter = "\t"
    )
  )
);
