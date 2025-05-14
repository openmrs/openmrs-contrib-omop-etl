#!/bin/bash


CONCEPTS_CSV_FILE="seed/CONCEPT.csv"

export PGPASSWORD=$TARGET_PASS


echo "📥 Loading csvs into tables..."

psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy concept_class FROM 'seed/CONCEPT_CLASS.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy domain FROM 'seed/DOMAIN.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy vocabulary FROM 'seed/VOCABULARY.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF


sed 's/"/""/g' $CONCEPTS_CSV_FILE > scripts/tmp/escaped_concepts.tmp.csv

psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy concept FROM 'scripts/tmp/escaped_concepts.tmp.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

