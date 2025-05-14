#!/bin/bash

echo "Dumping from $SRC_HOST:$SRC_PORT/$SRC_DB as $SRC_USER"

# Clone remote DB to local MySQL container
mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" "$SRC_DB" \
| mysql -h sqlmesh-db -uopenmrs -popenmrs openmrs

echo "Clone completed. Running SQLMesh plan..."

# Run SQLMesh
sqlmesh plan --no-prompts --auto-apply

. scripts/materialize_views.sh

export PGPASSWORD=$TARGET_PASS
# Drop if exists
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "DROP DATABASE IF EXISTS $TARGET_DB;"
# Recreate the database
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "CREATE DATABASE $TARGET_DB;"
# import the ddl
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d "$TARGET_DB" -f "omop-ddl/processed/ddl/01_OMOPCDM_postgresql_5.4_ddl.sql"

. scripts/migrate_to_postgres.sh
. scripts/import_concepts.sh
. scripts/execute_constraints.sh
