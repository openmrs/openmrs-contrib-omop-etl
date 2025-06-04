from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
from airflow.providers.docker.operators.docker import DockerOperator

default_args = {
    'owner': 'you',
    'retries': 0,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
        dag_id='run_two_scripts_hourly',
        default_args=default_args,
        start_date=datetime(2023, 1, 1),
        schedule='@hourly',  # runs every hour
        catchup=False
) as dag:

    run_core = DockerOperator(
        task_id='run_core_image',
        image='dbt-core',
        api_version='auto',
        auto_remove='never',
        docker_url='unix://var/run/docker.sock',
        network_mode='dbt_default',
        tmp_dir='/opt/airflow/tmp',
        environment={
            'SRC_HOST': 'omrsdb',
            'SRC_PORT': '3306',
            'SRC_USER': 'openmrs',
            'SRC_PASS': 'openmrs',
            'SRC_DB': 'openmrs',
            'SQLMESH_DB_ROOT_PASSWORD': 'openmrs',
            'TARGET_HOST': 'omop-db',
            'TARGET_PORT': '5432',
            'TARGET_USER': 'omop',
            'TARGET_PASS': 'omop',
            'TARGET_DB': 'omop',
            'ACHILLES_VOCAB_SCHEMA': 'vocab',
            'ACHILLES_RESULTS_SCHEMA': 'results'
        }
    )

    run_script2 = BashOperator(
        task_id='run_script2',
        bash_command='echo hello'
    )

    run_core >> run_script2  # ensures script2 runs after script1
