# Polk County dbt scaffold

- `models/staging/`: initial cleanup models and the template for the `raw.sales_raw` source declaration.
- `models/marts/`: analytical models you build from staging models.
- `seeds/`: small reference CSVs loaded with `dbt seed`.
- `analyses/`: SQL compiled by dbt but not materialized as tables or views.

The `.gitkeep` files retain the empty folders in Git.

## Configure

From the repository root, with dbt and BigQuery support installed:

```bash
bash scripts/save_outputs.sh
dbt debug --project-dir dbt --profiles-dir dbt
dbt parse --project-dir dbt --profiles-dir dbt
```

Run the export after applying Terraform and whenever its resource identifiers
change. The script reads Terraform outputs once and writes:

- `ingestion/outputs.json`: the existing ingestion configuration.
- `dbt/outputs.json`: the same Terraform output snapshot for reference.
- `dbt/profiles.yml`: the BigQuery connection profile with a concrete project ID.
- `dbt/models/staging/terraform_sources.yml`: the raw source with its concrete
  project and dataset IDs.

The last three files are generated and Git-ignored. dbt reads the generated YAML;
it does not automatically read `outputs.json`. Project/dataset environment variables
are no longer needed for this configuration.

Edit `profiles.yml.example` to change the transformation dataset (default
`polk_county_dbt_dev`), threads, or location. Edit `models/staging/sources.yml.example`
to change the raw source declaration or add source documentation/tests. Keep the
`__GCP_PROJECT_ID__` and `__RAW_DATASET_ID__` placeholders unquoted: the exporter
replaces them with safely quoted Terraform values. Re-run `save_outputs.sh` after
editing either template; edits to generated files are overwritten.

The exporter validates required output values and renders both templates before
writing. A Terraform or input-validation failure leaves the previous exports intact.
Files are staged first and replaced individually using atomic renames.

## Authentication

The profile uses `method: oauth` and the Application Default Credentials created by
the root README's `gcloud auth application-default login` step. On Linux/WSL, with
no credential override, dbt discovers:

```text
~/.config/gcloud/application_default_credentials.json
```

Credentials are not embedded in the generated files. `GOOGLE_APPLICATION_CREDENTIALS`
takes precedence over the default path; unset a stale override when using local ADC.
The transformation dataset is separate from the raw source dataset. Both currently
use the `US` location.

## Start a model

Create `models/staging/stg_sales.sql` when ready:

```sql
select *
from {{ source('raw', 'sales_raw') }}
```

Then run `dbt build --project-dir dbt --profiles-dir dbt` from the repository root.
The scaffold contains only a source declaration, so there are no models to build yet.

For the existing Python development container, mount this `dbt/` directory, install
the `dbt-bigquery` adapter with uv, and make ADC available inside the container.
The host's default credential path is not automatically visible there. Source
declarations describe existing BigQuery tables; they do not upload CSVs or create
the raw table.

## Estimate a saved SQL query in Cursor / VS Code

Open `polk-county-ingestion-pipeline/` as your editor workspace in WSL, where `uv`,
dbt, and your ADC credentials are available. After generating the dbt configuration:

1. Open a SQL file under `dbt/models/` or `dbt/analyses/`, such as
   `dbt/analyses/peek_sales.sql`, and save your edits.
2. Press **Ctrl+Shift+P** and choose **Tasks: Run Task**.
3. Select **BigQuery: Estimate active dbt SQL**.

The task uses the existing ingestion uv environment and BigQuery dependency. It
compiles the saved file with dbt to resolve `ref()` and `source()`, reads the freshly
compiled SQL, then asks BigQuery for a native dry-run estimate. Compilation artifacts
and logs are isolated in a temporary directory and cleaned up, including on failure.
The project's regular `target/` and extension artifacts are not used for the estimate.

The result appears in the task terminal as estimated bytes processed. The helper
does not execute the compiled SELECT or materialize a model. Compilation may fetch
warehouse metadata or evaluate your dbt macros. As with any dbt compilation, custom
macros such as `run_query()` can perform their own warehouse operations.

The Python helper uses local ADC, with `GOOGLE_APPLICATION_CREDENTIALS` taking
precedence when set. It reads the project ID from `dbt/outputs.json` and defaults to
the current `US` location. To invoke it directly from the repository root:

```bash
uv run --locked --project ingestion python scripts/estimate_query_cost.py dbt/analyses/peek_sales.sql
```

For a different warehouse location, add `--location REGION` to that command or the
task arguments. A valid zero-byte estimate is reported as zero. Missing references,
compilation failures, and BigQuery validation errors are printed with a nonzero exit
status instead of using stale SQL or an undefined result.

This estimates the compiled query's scan, not the cost of an entire dbt build or
future storage. On-demand billing minimums, free allowances, query caching, and your
pricing plan affect the actual bill. BigQuery-native dry runs avoid the extension's
failing `validate_sql()` / `EXPLAIN` estimator path.
