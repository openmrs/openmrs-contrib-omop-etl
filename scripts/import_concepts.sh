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

CONCEPTS_CSV_FILE="../seed/CONCEPT.csv"

export PGPASSWORD=$PG_PASSWORD


echo "📥 Loading csvs into tables..."

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy concept_class FROM '../seed/CONCEPT_CLASS.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy domain FROM '../seed/DOMAIN.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy vocabulary FROM '../seed/VOCABULARY.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF


sed 's/"/""/g' $CONCEPTS_CSV_FILE > tmp/escaped_concepts.tmp.csv

psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$TARGET_PG_DB" <<EOF
\copy concept FROM 'tmp/escaped_concepts.tmp.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

