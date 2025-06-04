#!/bin/bash

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
  *)
    echo "Unknown command: $command"
    echo "Usage: $0 {clone-omrs-db|run-sqlmesh}"
    exit 1
    ;;
esac
