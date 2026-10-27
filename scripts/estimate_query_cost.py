"""Compile a saved dbt SQL file and estimate its scan with a BigQuery dry run."""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from google.api_core.exceptions import GoogleAPICallError
from google.auth.exceptions import GoogleAuthError
from google.cloud import bigquery


def compile_sql(sql_file, project_dir, profiles_dir):
    if not sql_file.is_file() or sql_file.suffix.lower() != ".sql":
        raise ValueError(
            "Open and save a .sql model or analysis before running this task."
        )
    try:
        relative_path = sql_file.relative_to(project_dir).as_posix()
    except ValueError:
        raise ValueError(
            f"The SQL file must be inside the dbt project: {project_dir}"
        ) from None

    # Fresh, isolated artifacts prevent stale estimates and clashes with the LSP.
    with tempfile.TemporaryDirectory(prefix="dbt-dry-run-") as directory:
        temporary = Path(directory)
        command = [
            "dbt",
            "compile",
            "--project-dir",
            str(project_dir),
            "--profiles-dir",
            str(profiles_dir),
            "--select",
            f"path:{relative_path}",
            "--target-path",
            str(temporary / "target"),
            "--log-path",
            str(temporary / "logs"),
            "--write-json",
            "--no-version-check",
            "--no-send-anonymous-usage-stats",
        ]
        try:
            result = subprocess.run(
                command,
                cwd=project_dir,
                capture_output=True,
                text=True,
                timeout=120,
                # The return code is checked below, so dbt's output can go in the error.
                check=False,
            )
        except FileNotFoundError:
            raise RuntimeError(
                "dbt is not on PATH. Run this task in the WSL environment where dbt is installed."
            ) from None
        if result.returncode:
            details = "\n".join(
                part.strip() for part in (result.stdout, result.stderr) if part.strip()
            )
            raise RuntimeError(f"dbt compilation failed:\n{details}")

        manifest = json.loads((temporary / "target/manifest.json").read_text())
        nodes = [
            node
            for node in manifest.get("nodes", {}).values()
            if node.get("original_file_path") == relative_path
            and node.get("resource_type") in ("model", "analysis")
        ]
        if len(nodes) != 1:
            raise ValueError(
                "dbt did not identify one model or analysis for this file. Check the configured paths and whether it is enabled."
            )
        sql = nodes[0].get("compiled_code")
        if not isinstance(sql, str) or not sql.strip():
            raise ValueError("dbt did not produce compiled SQL for this file.")
        return sql


def read_project_id(project_dir):
    path = project_dir / "outputs.json"
    if not path.is_file():
        raise ValueError(
            "Missing dbt/outputs.json. Run bash scripts/save_outputs.sh first."
        )
    outputs = json.loads(path.read_text())
    try:
        project_id = outputs["gcp_project_id"]["value"]
    except (KeyError, TypeError):
        raise ValueError(
            "dbt/outputs.json is missing the Terraform gcp_project_id value."
        ) from None
    if not isinstance(project_id, str) or not project_id.strip():
        raise ValueError(
            "The Terraform gcp_project_id value must be a nonempty string."
        )
    return project_id


def estimate_bytes(client, sql, location):
    config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    job = client.query(sql, job_config=config, location=location, timeout=60)
    if job.total_bytes_processed is None:
        raise RuntimeError(
            "BigQuery validated the SQL but did not return a bytes-processed estimate."
        )
    return job.total_bytes_processed


def readable_bytes(byte_count):
    amount = float(byte_count)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB", "PiB"):
        if amount < 1024 or unit == "PiB":
            return f"{amount:.1f} {unit}"
        amount /= 1024


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "sql_file", type=Path, help="Saved SQL model or analysis to estimate"
    )
    parser.add_argument(
        "--project-dir", type=Path, default=Path(__file__).resolve().parents[1] / "dbt"
    )
    parser.add_argument(
        "--profiles-dir", type=Path, help="Defaults to the dbt project directory"
    )
    parser.add_argument(
        "--location", default="US", help="BigQuery location; default: US"
    )
    args = parser.parse_args()
    project_dir = args.project_dir.resolve()
    profiles_dir = (args.profiles_dir or project_dir).resolve()
    try:
        project_id = read_project_id(project_dir)
        sql = compile_sql(args.sql_file.resolve(), project_dir, profiles_dir)
        # Use local Application Default Credentials, just like the dbt OAuth profile.
        with bigquery.Client(project=project_id) as client:
            byte_count = estimate_bytes(client, sql, args.location)
    except (
        OSError,
        ValueError,
        RuntimeError,
        subprocess.TimeoutExpired,
        GoogleAPICallError,
        GoogleAuthError,
    ) as error:
        print(f"Estimate failed: {error}", file=sys.stderr)
        return 1

    print(f"File: {args.sql_file.resolve()}")
    print(f"BigQuery dry run: valid ({project_id}, {args.location})")
    print(f"Estimated bytes processed: {byte_count:,} ({readable_bytes(byte_count)})")
    print(
        "The SELECT was not executed. This is a scan estimate, not a dollar quote or a full dbt build estimate."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
