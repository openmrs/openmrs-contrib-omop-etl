MODEL (
  name omop_db.DOMAIN,
  kind SEED (
    path '$root/seed/DOMAIN.csv',
    csv_settings (
      delimiter = "\t"
    )
  )
);
