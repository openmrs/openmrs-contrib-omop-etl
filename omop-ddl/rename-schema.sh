rm -rf processed
mkdir processed

for file in *.sql; do
  sed 's/@cdmDatabaseSchema/public/g' "$file" > "processed/$file"
done
