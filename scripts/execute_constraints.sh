#!/bin/bash

# === CONFIG ===
PG_USER="omop"
PG_PASSWORD="omop"
PG_HOST="localhost"
PG_PORT="5432"
TARGET_PG_DB="omop"


export PGPASSWORD=$PG_PASSWORD

echo "🔗 Connecting to PostgreSQL and executing constraint scripts..."

for sql_file in ../omop-ddl/processed/constraints/*.sql; do
  echo "⚙️  Executing $sql_file..."
  psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" -f "$sql_file"
done

echo "✅ All constraint scripts executed."
