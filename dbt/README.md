# Polk County dbt scaffold

- `models/sources.yml.example`: the template for the `raw.sales_raw` source declaration.
- `models/staging/`: typed, trimmed copies of the raw sales data (`stg_sale_data`, `stg_parcels`).
- `models/intermediate/`: cleanup and coding between staging and marts (`int_sales`, `int_parcels`).
- `models/marts/dims/`: dimension tables, including the `dim_*` code lookups built from the seeds.
- `models/marts/facts/`: fact tables (`fct_sales`).
- `seeds/`: the `valid_*` lookup CSVs loaded with `dbt seed`.
- `macros/`: shared SQL, such as `lookup_id` and `building_id`.
- `analyses/`: SQL compiled by dbt but not materialized as tables or views.

The `.gitkeep` files retain the empty folders in Git.

## Configure

From the repository root, with dbt and BigQuery support installed:

```bash
terraform -chdir=terraform plan
terraform -chdir=terraform apply
bash scripts/save_outputs.sh
dbt debug --project-dir dbt --profiles-dir dbt
dbt parse --project-dir dbt --profiles-dir dbt
```

Run the export after applying Terraform and whenever its resource identifiers
change. The script reads Terraform outputs once and writes:

- `ingestion/outputs.json`: the existing ingestion configuration.
- `dbt/outputs.json`: the same Terraform output snapshot for reference.
- `dbt/profiles.yml`: the BigQuery connection profile with the concrete project ID
  and default dataset.
- `dbt/models/sources.yml`: the raw source with its concrete project and dataset
  IDs.

The last three files are generated and Git-ignored. dbt reads the generated YAML;
it does not automatically read `outputs.json`. Project/dataset environment variables
are no longer needed for this configuration.

### Datasets

Terraform creates every BigQuery dataset, and dbt creates and replaces the tables
inside them. Each dbt folder builds into its own dataset:

| Folder | Dataset | Stored test failures |
|---|---|---|
| `seeds/` | `seeds` | |
| `models/staging/` | `staging` | `staging_audit` |
| `models/intermediate/` | `intermediate` | `intermediate_audit` |
| `models/marts/dims/` | `marts_dims` | `marts_dims_audit` |
| `models/marts/facts/` | `marts_facts` | `marts_facts_audit` |

The `+schema` settings in `dbt_project.yml` map folders to datasets, and
`macros/generate_schema_name.sql` makes dbt use those names as they are instead of
prefixing them with the profile's dataset. The datasets themselves are the
`dbt_datasets` map in `terraform/gcp.tf`. To add one, add the name in both places,
then run `terraform apply` before `dbt build`.

The profile's `dataset`, from the `gcp_bigquery_transform_id` output, is `staging`.
It only receives models that have no `+schema` folder mapping. The `raw.sales_raw`
source uses `gcp_bigquery_raw_ingest_id`, independently of the model datasets.
Apply Terraform before saving outputs, since changing an output in the configuration
alone does not update the outputs stored in Terraform state.

`terraform destroy` deletes every dataset along with its tables. A full rebuild is
`terraform apply`, `scripts/save_outputs.sh`, the ingestion, then `dbt build`.

Edit `profiles.yml.example` to change threads or location. Edit
`models/sources.yml.example` to change the raw source declaration or add
source documentation/tests. Keep `__GCP_PROJECT_ID__`, `__RAW_DATASET_ID__`, and
`__TRANSFORM_DATASET_ID__` unquoted: the exporter replaces them with safely quoted
Terraform values. Re-run `save_outputs.sh` after editing either template; edits to
generated files are overwritten.

Changing a folder's dataset makes `ref()` point to models in the new dataset; it
does not move existing tables. Rebuild the moved models before querying them, then
delete the old copies, since dbt never drops tables. For example:

```bash
dbt build --project-dir dbt --profiles-dir dbt --select fct_sales
```

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
The raw source dataset and the dbt datasets all use the `US` location.

## Add a model

The layers build on each other: `raw.sales_raw` → staging → intermediate → marts.
To add a model:

1. Put the SQL file in the folder for its layer. The folder decides its dataset
   (see [Datasets](#datasets)).
2. Add an entry for it in that folder's YAML file (`staging.yml`, `intermediate.yml`,
   `dims.yml` or `facts.yml`). The existing models use enforced contracts, so list
   every column with its `data_type`, plus any keys and tests.
3. Build it, along with everything downstream of it, from the repository root:

```bash
dbt build --project-dir dbt --profiles-dir dbt --select my_model+
```

Run `dbt build --project-dir dbt --profiles-dir dbt` with no selection to rebuild
the whole project, including the seeds.

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
