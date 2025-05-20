#!/bin/bash

# === CONFIG ===
TARGET_MYSQL_DB="public"




#echo "🧹 Truncating all tables in PostgreSQL before migration..."
#
#psql postgresql://$TARGET_USER:$TARGET_PASS@$TARGET_HOST:$TARGET_PORT/$TARGET_DB <<EOSQL
#DO \$\$
#DECLARE
#    r RECORD;
#BEGIN
#    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
#        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' RESTART IDENTITY CASCADE';
#    END LOOP;
#END
#\$\$;
#EOSQL
#

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

