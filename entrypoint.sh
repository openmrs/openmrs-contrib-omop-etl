#!/bin/bash

# Wait for MySQL container
echo "Waiting for dab-db to be ready..."
until mysqladmin ping -h sqlmesh-db -uopenmrs -popenmrs --silent; do
  sleep 2
done

#bash scripts/script.sh

tail -f /dev/null
