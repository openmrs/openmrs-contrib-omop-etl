#!/bin/bash

export PGPASSWORD=$TARGET_PASS
MYSQL_USER="root"
MYSQL_PASSWORD="openmrs"
MYSQL_HOST="sqlmesh-db"
MYSQL_PORT="3306"
SOURCE_DB="omop_db"
TARGET_MYSQL_DB="public"



clone-omrs-db() {
  echo "Cloning OpenMRS database..."
  mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" "$SRC_DB" \
  | mysql -h sqlmesh-db -uopenmrs -popenmrs openmrs
  echo "Clone completed."
}

run-sqlmesh() {
  echo "Running SQLMesh plan..."
  sqlmesh plan --no-prompts --auto-apply
  echo "SQLMesh plan completed."
}

materialize-views() {
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

migrate_to_postgres() {
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

  cat <<EOF > scripts/tmp/temp_pgloader.load
LOAD DATABASE
       FROM mysql://root:$SQLMESH_DB_ROOT_PASSWORD@sqlmesh-db:$MYSQL_PORT/$TARGET_MYSQL_DB
       INTO postgresql://$TARGET_USER:$TARGET_PASS@$TARGET_HOST:$TARGET_PORT/$TARGET_DB

        WITH include no drop,
             data only

        CAST type int to integer,
             type datetime to timestamp;
EOF
  pgloader scripts/tmp/temp_pgloader.load

  echo "✅ Migration complete: All materialized views are now in PostgreSQL database '$TARGET_DB'."
}

command="$1"
shift

echo "DEBUG: received command: $command"
echo "DEBUG: all args: $@"

case "$command" in
  clone-omrs-db)
    clone-omrs-db
    ;;
  run-sqlmesh)
    run-sqlmesh
    ;;
  materialize-views)
    materialize-views
    ;;
  migrate-to-postgres)
    migrate_to_postgres
    ;;
  *)
    echo "Unknown command: $command"
    echo "Usage: $0 {clone-omrs-db|run-sqlmesh}"
    exit 1
    ;;
esac
