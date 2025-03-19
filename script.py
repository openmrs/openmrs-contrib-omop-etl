import pandas as pd

# Load large CSV in chunks
chunk_size = 500000  # Adjust as needed
csv_file = "seed/CONCEPT.csv"

for i, chunk in enumerate(pd.read_csv(csv_file, delimiter="\t", chunksize=chunk_size)):
    chunk.to_csv(f"seed/CONCEPT_part{i}.csv", index=False, sep="\t")
