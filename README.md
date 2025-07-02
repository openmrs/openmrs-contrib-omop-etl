

## 🏗️ Setting Up the Project

Follow these steps to get the project up and running:

### 1. Clone the repository

```bash
git clone git@github.com:jayasanka-sack/openmrs-to-omop.git
cd openmrs-to-omop
```

---

### 2. Build the Required Images

Run the following command to build the `omop-etl-core` and `omop-etl-achilles` images:

```bash
docker compose --profile manual build
```

---

### 3. Start the services

```bash
docker compose up
```

---

### 4. Generate the Usagi Input File

Run the following command:

```bash
docker compose run --rm core generate-concepts-usagi-input
```

This will generate a CSV file containing OpenMRS concept IDs, names, and their usage frequencies.

✅ **Location of the generated file:**

```
/concepts/concepts_for_usagi_mapping
```

You’ll import this file into **Usagi** to map your OpenMRS concepts to OMOP standard concepts.

---

### 5. Import the File into Usagi

#### a. Download and Install Usagi

If you don’t have Usagi installed yet:

- Go to the official OHDSI page for Usagi:  
  [https://ohdsi.github.io/Usagi/](https://ohdsi.github.io/Usagi/)
- Download the latest release suitable for your operating system.
- Extract and run Usagi.

---

#### b. Import the OMOP Vocabulary

Before you can map your concepts, you must load the OMOP vocabulary into Usagi.

- Download the vocabulary files (e.g. `CONCEPT.csv`, `VOCABULARY.csv`, etc.) from [OHDSI Athena](https://athena.ohdsi.org/).
- In Usagi, go to:

```
File > Import Vocabulary
```

- Select the folder containing the vocabulary CSV files.

> **Note:** This is a one-time task unless you update your vocabularies in the future.

---

#### c. Import the Concepts for Mapping

- In Usagi, go to:

```
File > Import Codes
```

- Select the file you generated in Step 4:

```
/concepts/concepts_for_usagi_mapping
```

Usagi will automatically attempt to map your source concepts to standard OMOP concepts based on the concept names and frequencies.

---

#### d. Review and Save the Mapping

- Review the suggested mappings:
    - Approve mappings
    - Change mappings
    - Or leave some unmapped for later

- Once you’re done, save the mapping:

![](docs/img/usagi.jpeg)
```
File > Save As
```

- Save the file in the `concepts` folder and name it:

```
mapping.csv
```

**Location of saved mapping file:**

```
/concepts/mapping.csv
```

This file will later be used by **SQLMesh** during ETL processing.

---

#### e. Updating Your Mapping Later

If you wish to change mappings in the future:

- Open Usagi
- Go to:

```
File > Apply Previous Mapping
```

- Import your existing mapping file (`mapping.csv`), and make further edits as needed.




### 6. **Run the core service to convert the data**  
    
    Typical usage:

```bash
docker compose run --rm core <command>
```

**Available Commands**

| Command                         | Description                                                                                                                        |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| `clone-openmrs-db`              | Clones the OpenMRS database from a configured source into the `openmrs` MySQL database inside the container.                       |
| `generate-concepts-usagi-input` | Generates a list of concepts to import to Usagi.                                                                                   |
| `apply-sqlmesh-plan`            | Runs the SQLMesh plan with `--no-prompts` and auto-applies changes.                                                                |
| `materialize-mysql-views`       | Extracts all views from the `omop_db` MySQL schema and materializes them as physical tables into the `public` schema.              |
| `migrate-to-postgresql`         | Migrates the materialized MySQL database to PostgreSQL using `pgloader`, recreating the target PostgreSQL DB and loading OMOP DDL. |
| `import-omop-concepts`          | Imports OMOP vocabulary/concept CSVs (`CONCEPT_CLASS`, `DOMAIN`, `VOCABULARY`, and `CONCEPT`) into the PostgreSQL database.        |
| `apply-omop-constraints`        | Executes SQL constraint scripts from `omop-ddl/processed/constraints/` against the PostgreSQL database.                            |
| `run-full-pipeline`             | Executes all steps: clone DB, apply SQLMesh, materialize views, migrate to PostgreSQL, import concepts, and apply constraints.     |

**Example**

To run the full pipeline:

```bash
docker compose run --rm core run-all
```

Or run individual steps:

```bash
docker compose run --rm core materialize-views
```
### 7. **Run Achilles to generate data summaries** (Check What Achilles does below.)
   ```
   docker compose run achilles
   ``` 
### 8. **Run DQD to perform data quality checks**  
   This runs the [OHDSI Data Quality Dashboard (DQD)](https://github.com/OHDSI/DataQualityDashboard) on the OMOP database.
   ```bash
    docker compose run --rm dqd run 
   ```
### 9. **View the Data Quality Dashboard**  
      This serves the DQD results on a local web server. Once it's running, open your browser and go to [http://localhost:3000](http://localhost:3000).
   ```
   docker compose run --rm --service-ports dqd view
   ``` 

## 🧪 What does Achilles do?
Achilles analyzes the OMOP CDM data and generates summary statistics, data quality metrics, and precomputed reports. These results are essential for visualizations in tools like Atlas.

When you run:

```
docker compose run achilles
```
- ✅ It connects to your omop-db
- ✅ Scans and summarizes data in the public schema
- ✅ Produces results in the Achilles_results and Achilles_analysis tables
- ✅ Prepares your OMOP CDM for use with the web-based Atlas UI

## 🌀 Optional: Run with Airflow
You can run this project with Apache Airflow to visually orchestrate and schedule your data pipeline.

### To start with Airflow:
```bash
docker compose -f docker-compose.yml -f docker-compose.airflow.yml up
```

This will launch the Airflow UI at:
👉 http://localhost:8080

Login credentials:\
Username: airflow\
Password: airflow

You can use the UI to manually trigger DAGs that run your pipeline steps.
![](docs/img/airflow.jpeg)


## Setting Up Git LFS for This Repository

This repository uses **Git Large File Storage (LFS)** to handle large files like `CONCEPT.csv`. If you're cloning or pulling the repository, make sure to set up Git LFS to download the actual files instead of pointers.

### Step 1: Install Git LFS
Before cloning, install Git LFS:

- **macOS (Homebrew)**  
  ```sh
  brew install git-lfs
  ```

- **Linux (Ubuntu/Debian)**
  ```sh
  sudo apt update && sudo apt install git-lfs
  ```

- **Windows**  
  Download and install Git LFS from [Git LFS official site](https://git-lfs.github.com/).

### Step 2: Clone the Repository
After installing Git LFS, clone the repository:

```sh
git clone https://github.com/jayasanka-sack/openmrs-to-omop.git
cd openmrs-to-omop
```

Git LFS will automatically download the large files.

### Step 3: Pulling Updates
If you have already cloned the repository before installing Git LFS, or if you are pulling new changes, run:

```sh
git lfs install
git lfs pull
```

This ensures all large files are properly downloaded.

### Troubleshooting
If you see pointer files instead of actual data when opening a large file (e.g., `CONCEPT.csv`), it means Git LFS is not set up correctly. Run:

```sh
git lfs pull
```

For more information, refer to the [Git LFS documentation](https://git-lfs.github.com/).
