#!/bin/bash

export PGPASSWORD=$TARGET_PASS

echo "🔗 Connecting to PostgreSQL and executing constraint scripts..."

for sql_file in omop-ddl/processed/constraints/*.sql; do
  echo "⚙️  Executing $sql_file..."
  psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" -f "$sql_file"
done

echo "✅ All constraint scripts executed."
