#!/bin/bash

# Wait for MySQL container
echo "Waiting for dab-db to be ready..."
until mysqladmin ping -h sqlmesh-db -uopenmrs -popenmrs --silent; do
  sleep 2
done

echo "dab-db is ready."

echo "SQLMesh run complete. Keeping container alive..."
tail -f /dev/null
