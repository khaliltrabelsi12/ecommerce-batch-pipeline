from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

# =========================
# PATHS
# =========================
DBT_PROJECT_DIR = "/mnt/c/Users/trabe/ecommerce-batch-pipeline/dbt_project"
DBT_PROFILES_DIR = "/home/khalil/.dbt"

# IMPORTANT:
# replace this with the exact output of: which dbt
DBT_BIN = "/mnt/c/Users/trabe/ecommerce-batch-pipeline/venv/bin/dbt"

# =========================
# DEFAULT ARGS
# =========================
DEFAULT_ARGS = {
    "owner": "khalil",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
}

# =========================
# HELPER
# =========================
def dbt_cmd(command: str) -> str:
    return (
        f"cd {DBT_PROJECT_DIR} && "
        f"{DBT_BIN} {command} --profiles-dir {DBT_PROFILES_DIR}"
    )

# =========================
# DAG
# =========================
with DAG(
    dag_id="ecommerce_dbt_pipeline",
    description="Advanced dbt orchestration for ecommerce project",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    dagrun_timeout=timedelta(hours=2),
    tags=["ecommerce", "dbt", "airflow", "advanced"],
) as dag:

    source_check = BashOperator(
        task_id="source_check",
        bash_command=dbt_cmd("debug"),
        execution_timeout=timedelta(minutes=15),
    )

    with TaskGroup(group_id="staging") as staging_group:
        run_staging = BashOperator(
            task_id="run_staging",
            bash_command=dbt_cmd("run --select tag:staging"),
            execution_timeout=timedelta(minutes=20),
        )

        test_staging = BashOperator(
            task_id="test_staging",
            bash_command=dbt_cmd("test --select tag:staging"),
            execution_timeout=timedelta(minutes=20),
        )

        run_staging >> test_staging

    with TaskGroup(group_id="intermediate") as intermediate_group:
        run_intermediate = BashOperator(
            task_id="run_intermediate",
            bash_command=dbt_cmd("run --select tag:intermediate"),
            execution_timeout=timedelta(minutes=20),
        )

        test_intermediate = BashOperator(
            task_id="test_intermediate",
            bash_command=dbt_cmd("test --select tag:intermediate"),
            execution_timeout=timedelta(minutes=20),
        )

        run_intermediate >> test_intermediate

    with TaskGroup(group_id="marts") as marts_group:
        run_marts = BashOperator(
            task_id="run_marts",
            bash_command=dbt_cmd("run --select tag:mart"),
            execution_timeout=timedelta(minutes=20),
        )

        test_marts = BashOperator(
            task_id="test_marts",
            bash_command=dbt_cmd("test --select tag:mart"),
            execution_timeout=timedelta(minutes=20),
        )

        run_marts >> test_marts

    source_check >> staging_group >> intermediate_group >> marts_group