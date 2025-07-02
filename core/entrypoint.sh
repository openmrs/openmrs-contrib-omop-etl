#!/bin/bash

export PGPASSWORD=$TARGET_PASS
MYSQL_USER="root"
MYSQL_PASSWORD="openmrs"
MYSQL_HOST="sqlmesh-db"
MYSQL_PORT="3306"
SOURCE_DB="omop_db"
TARGET_MYSQL_DB="public"
CONCEPTS_CSV_FILE="seed/CONCEPT.csv"
TEMP_DIR="tmp"

clone-openmrs-db() {
  echo "Cloning OpenMRS database..."
  mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" "$SRC_DB" \
  | mysql -h sqlmesh-db -uopenmrs -popenmrs openmrs
  echo "Clone completed."
}

generate-concepts-usagi-input() {
  python3 export_concepts.py
}

apply-sqlmesh-plan() {
  echo "Running SQLMesh plan..."
  sqlmesh plan --no-prompts --auto-apply
  echo "SQLMesh plan completed."
}

materialize-mysql-views() {
  echo "Materializing views..."

  # === Create target MySQL DB if it doesn't exist ===
  echo "🛠️ Create target MySQL DB if it doesn't exist"
  mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P $MYSQL_PORT --protocol=TCP -e "CREATE DATABASE IF NOT EXISTS \`$TARGET_MYSQL_DB\`;"

  #=== Step 1: Get all view names from the source DB ===
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
  echo "Views materialized."
}

migrate-to-postgresql() {
  echo "Migrating to PostgreSQL..."
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

  # # === Step 3: Migrate the entire MySQL DB to PostgreSQL ===
  echo "🚚 Running pgloader to migrate entire database '$TARGET_MYSQL_DB' to PostgreSQL '$TARGET_DB'..."

  cat <<EOF > $TEMP_DIR/temp_pgloader.load
LOAD DATABASE
       FROM mysql://root:$SQLMESH_DB_ROOT_PASSWORD@sqlmesh-db:$MYSQL_PORT/$TARGET_MYSQL_DB
       INTO postgresql://$TARGET_USER:$TARGET_PASS@$TARGET_HOST:$TARGET_PORT/$TARGET_DB

        WITH include no drop,
             data only

        CAST type int to integer,
             type datetime to timestamp;
EOF
  pgloader $TEMP_DIR/temp_pgloader.load

  echo "✅ Migration complete: All materialized views are now in PostgreSQL database '$TARGET_DB'."
}

import-omop-concepts() {
  echo "Importing concepts..."
  psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy concept_class FROM 'seed/CONCEPT_CLASS.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

  psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy domain FROM 'seed/DOMAIN.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

  psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy vocabulary FROM 'seed/VOCABULARY.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF


  sed 's/"/""/g' $CONCEPTS_CSV_FILE > $TEMP_DIR/escaped_concepts.tmp.csv

  psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" <<EOF
\copy concept FROM '$TEMP_DIR/escaped_concepts.tmp.csv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
EOF

  echo "Concepts imported."
}

apply-omop-constraints() {
  echo "🔗 Connecting to PostgreSQL and executing constraint scripts..."

  for sql_file in omop-ddl/processed/constraints/*.sql; do
    echo "⚙️  Executing $sql_file..."
    psql -U "$TARGET_USER" -h "$TARGET_HOST" -p "$TARGET_PORT" -d "$TARGET_DB" -f "$sql_file"
  done

  echo "✅ All constraint scripts executed."
}

command="$1"
shift

echo "DEBUG: received command: $command"
echo "DEBUG: all args: $@"

# Create tmp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

case "$command" in
  clone-openmrs-db)
    clone-openmrs-db
    ;;
  generate-concepts-usagi-input)
    generate-concepts-usagi-input
    ;;
  apply-sqlmesh-plan)
    apply-sqlmesh-plan
    ;;
  materialize-mysql-views)
   materialize-mysql-views
    ;;
  migrate-to-postgresql)
    migrate-to-postgresql
    ;;
  import-omop-concepts)
    import-omop-concepts
    ;;
  apply-omop-constraints)
    apply-omop-constraints
    ;;
  run-full-pipeline)
    echo "Step 1/6"
    clone-openmrs-db
    echo "Step 2/6"
    apply-sqlmesh-plan
    echo "Step 3/6"
    materialize-mysql-views
    echo "Step 4/6"
    migrate-to-postgresql
    echo "Step 5/6"
    import-omop-concepts
    echo "Step 6/6"
    apply-omop-constraints
    ;;
  *)
    echo "Unknown command: $command"
    echo "Usage: $0 {clone-openmrs-db|generate-concepts-usagi-input|apply-sqlmesh-plan|materialize-mysql-views|migrate-to-postgresql|import-omop-concepts|apply-omop-constraints|run-full-pipeline}"
    exit 1
    ;;
esac

# Remove temp directory
rm -rf "$TEMP_DIR"
