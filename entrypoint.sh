#!/bin/bash

# Wait for MySQL container
echo "Waiting for dab-db to be ready..."
until mysqladmin ping -h sqlmesh-db -uopenmrs -popenmrs --silent; do
  sleep 2
done

echo "dab-db is ready. Starting DB clone..."

echo "Dumping from $SRC_HOST:$SRC_PORT/$SRC_DB as $SRC_USER"

# Clone remote DB to local MySQL container
mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" "$SRC_DB" \
| mysql -h sqlmesh-db -uopenmrs -popenmrs openmrs

echo "Clone completed. Running SQLMesh plan..."

# Run SQLMesh
#sqlmesh plan --config config.toml



echo "SQLMesh run complete. Keeping container alive..."
tail -f /dev/null
