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

