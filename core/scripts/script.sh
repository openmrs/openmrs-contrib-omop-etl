#!/bin/bash
set -e  # Exit on any error

echo "Dumping from $SRC_HOST:$SRC_PORT/$SRC_DB as $SRC_USER"

# Clone remote DB to local MySQL container
mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" "$SRC_DB" \
| mysql -h sqlmesh-db -uopenmrs -popenmrs openmrs

echo "Clone completed. Running SQLMesh plan..."

# Run SQLMesh
sqlmesh plan --no-prompts --auto-apply

. scripts/materialize_views.sh

export PGPASSWORD=$TARGET_PASS

# Terminate connections to the target DB
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$TARGET_DB' AND pid <> pg_backend_pid();
"

# Drop if exists
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "DROP DATABASE IF EXISTS $TARGET_DB;"
# Recreate the database
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "CREATE DATABASE $TARGET_DB;"
# import the ddl
psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d "$TARGET_DB" -f "omop-ddl/processed/ddl/01_OMOPCDM_postgresql_5.4_ddl.sql"

. scripts/migrate_to_postgres.sh
. scripts/import_concepts.sh
. scripts/execute_constraints.sh

# Create achilles schemas
echo "🟡 Creating achilles schema $ACHILLES_VOCAB_SCHEMA and $ACHILLES_RESULTS_SCHEMA"

#psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -tc "SELECT 1 FROM WHERE datname = '$ACHILLES_VOCAB_SCHEMA'" | grep -q 1 || \
#psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "CREATE DATABASE $ACHILLES_VOCAB_SCHEMA"
#
#psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$ACHILLES_RESULTS_SCHEMA'" | grep -q 1 || \
#psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d postgres -c "CREATE DATABASE $ACHILLES_RESULTS_SCHEMA"

echo "✅ Creating achilles schema $ACHILLES_VOCAB_SCHEMA and $ACHILLES_RESULTS_SCHEMA completed"
