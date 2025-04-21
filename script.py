#!/bin/bash

# === CONFIG ===
MYSQL_USER="root"
MYSQL_PASSWORD="openmrs"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
SOURCE_DB="omop_db"
TARGET_MYSQL_DB="public"

PG_USER="omop"
PG_PASSWORD="omop"
PG_HOST="localhost"
PG_PORT="5432"
TARGET_PG_DB="omop"

CONCEPTS_CSV_FILE="seed/CONCEPT.csv"


# === Create target MySQL DB if it doesn't exist ===
echo "🛠️ Create target MySQL DB if it doesn't exist"
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -e "CREATE DATABASE IF NOT EXISTS \`$TARGET_MYSQL_DB\`;"

=== Step 1: Get all view names from the source DB ===
echo "🔍 Fetching all views from '$SOURCE_DB'..."
VIEW_LIST=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -N -s -e "
SELECT TABLE_NAME FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = '$SOURCE_DB';
")

if [ -z "$VIEW_LIST" ]; then
  echo "❌ No views found in '$SOURCE_DB'. Nothing to do."
  exit 1
fi

echo "✅ Found views:"
echo "$VIEW_LIST"

# === Step 2: Materialize each view into the target MySQL DB ===
for VIEW_NAME in $VIEW_LIST; do
  echo "🚧 Materializing view '$VIEW_NAME' into '$TARGET_MYSQL_DB'..."
  mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -e "
  DROP TABLE IF EXISTS \`$TARGET_MYSQL_DB\`.\`$VIEW_NAME\`;
  CREATE TABLE \`$TARGET_MYSQL_DB\`.\`$VIEW_NAME\` AS SELECT * FROM \`$SOURCE_DB\`.\`$VIEW_NAME\`;
  "

  # Verify materialization
  TABLE_EXISTS=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -N -s -e "
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = '$TARGET_MYSQL_DB' AND TABLE_NAME = '$VIEW_NAME';
  ")

  if [[ "$TABLE_EXISTS" =~ ^[0-9]+$ && "$TABLE_EXISTS" -eq 1 ]]; then
    echo "✅ '$VIEW_NAME' successfully materialized."
  else
    echo "❌ Failed to materialize '$VIEW_NAME'."
  fi
done

# === fix the observation table

mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -e "
      ALTER TABLE \`$TARGET_MYSQL_DB\`.OBSERVATION
        MODIFY COLUMN observation_concept_id INT,
        MODIFY COLUMN observation_source_concept_id INT,
    MODIFY COLUMN observation_event_id BIGINT;
      "

echo "🧹 Truncating all tables in PostgreSQL before migration..."

psql postgresql://$PG_USER:$PG_PASSWORD@$PG_HOST:$PG_PORT/$TARGET_PG_DB <<EOSQL
DO \$\$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' RESTART IDENTITY CASCADE';
    END LOOP;
END
\$\$;
EOSQL


# # === Step 3: Migrate the entire MySQL DB to PostgreSQL ===
echo "🚚 Running pgloader to migrate entire database '$TARGET_MYSQL_DB' to PostgreSQL '$TARGET_PG_DB'..."

cat <<EOF > temp_pgloader.load
LOAD DATABASE
     FROM mysql://$MYSQL_USER:$MYSQL_PASSWORD@$MYSQL_HOST:$MYSQL_PORT/$TARGET_MYSQL_DB
     INTO postgresql://$PG_USER:$PG_PASSWORD@$PG_HOST:$PG_PORT/$PG_DB

      WITH include no drop,
           data only

      CAST type int to integer,
           type datetime to timestamp;
EOF

pgloader temp_pgloader.load

echo "✅ Migration complete: All materialized views are now in PostgreSQL database '$TARGET_PG_DB'."


export PGPASSWORD=$PG_PASSWORD


echo "📥 Loading csvs into tables..."

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy concept_class FROM 'seed/CONCEPT_CLASS.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy domain FROM 'seed/DOMAIN.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy vocabulary FROM 'seed/VOCABULARY.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF


sed 's/"/""/g' $CONCEPTS_CSV_FILE > escaped_concepts.temp.csv

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy concept FROM 'escaped_concepts.temp.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

echo "🔗 Connecting to PostgreSQL and executing constraint scripts..."

for sql_file in omop-ddl/processed/constraints/*.sql; do
  echo "⚙️  Executing $sql_file..."
  psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" -f "$sql_file"
done

echo "✅ All constraint scripts executed."
