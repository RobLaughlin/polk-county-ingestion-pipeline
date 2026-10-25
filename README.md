# Polk County Ingestion Pipeline

Loads residential sale records published by the
[Polk County Assessor](https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=downloads/res_sales_polk)
in Iowa into BigQuery for analysis. As of October 2026 the raw table holds 403,264 sales
from January 1990 through July 2026.

Terraform creates the Google Cloud infrastructure, and a Docker Compose container runs
the Python ingestion job, built with uv.

## How it works

1. Terraform creates a versioned Cloud Storage bucket, a `raw` BigQuery dataset for the
   loaded files, and one dataset per dbt layer for the models.
2. The ingestion job downloads each yearly sale file, from 1990 to the current year, and
   retries failed downloads.
3. It compares each file's MD5 hash with the copy in Cloud Storage and uploads only new or
   changed files.
4. It then reloads the 80-column `sales_raw` table in BigQuery from every CSV in the bucket.
5. dbt cleans the raw table and builds a star schema: `fct_sales` plus parcel, building,
   date, and code dimensions. It tests each layer.

## Status

- Done: infrastructure, concurrent ingestion with change detection, the raw BigQuery load, dbt
  connection settings generated from Terraform outputs, a dry-run script that estimates a
  dbt model's BigQuery scan before it runs, and the dbt models: staging, intermediate
  cleanup, and the star schema, with key and relationship tests.
- Planned: an ingestion log table in BigQuery.

The finished pipeline will also be submitted as the final project for Harvard's CS50
Introduction to Databases with SQL.

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) version >= 1.2.0 Installed
2. An already existing [GCP Account](https://console.cloud.google.com/freetrial/)
3. [Google Cloud Cli](https://docs.cloud.google.com/sdk/docs/install-sdk) Installed
4. [Docker](https://docs.docker.com/get-started/get-docker/) with Compose v2 Installed
5. [Python 3](https://www.python.org/downloads/) Installed
6. [dbt Fusion](https://docs.getdbt.com/docs/fusion/install-fusion) 2.x Installed, which includes the BigQuery adapter

## Instructions

1. Create a [GCP Project](https://console.cloud.google.com/projectcreate) and make note of the Project ID.
2. Enable the Google Compute Engine API for your project in the [GCP Console](https://console.developers.google.com/apis/library/compute.googleapis.com).
3. Run the following command: `gcloud auth application-default login` . If running on WSL2, append `--no-launch-browser` to the command. On Linux/WSL, the default ADC file is `~/.config/gcloud/application_default_credentials.json`; Terraform and local dbt use it automatically when no credential override is set.
4. `cd` into the `terraform` directory, set your `terraform.tfvars` variables using the `terraform.tfvars.example` template, and run `terraform init`.
5. Run `terraform plan` and if everything looks good to you, run `terraform apply` to create the GCP infrastructure. Infrastructure can be destroyed with `terraform destroy`. You can also use `terraform show` to show the current terraform state.
6. Run `./scripts/save_outputs.sh` to export Terraform outputs for ingestion and generate the local dbt profile and raw-source configuration.
7. Run `./scripts/ingest.sh` to run the ingestion script, which handles up to 8 yearly files at a time (`MAX_NUM_THREADS` in `ingestion/ingest.py`). It first runs `./scripts/build_image.sh`, which builds the ingestion image if it isn't built yet, and `./scripts/ingest.sh` then runs `./scripts/run_container.sh`, which starts the ingestion container if it isn't running. Both can also be run on their own. Since an existing image is never rebuilt, run `docker compose build` after editing `docker/Dockerfile`. Stop the container with `docker compose down`.
8. `cd` into the `dbt` directory and run `dbt deps` to install the dbt packages, then `dbt build` to load the seeds and build and test every model. Rows that fail a test are saved in the matching `_audit` dataset.
9. After editing a model, rebuild it and everything that uses it with `dbt build --select my_model+`. This doesn't rebuild the models it reads from, so if you edited more than one, run `dbt build`.
10. Run `dbt docs generate && dbt docs serve` from the `dbt` directory to view the data descriptions: every model and column, where each column comes from, and the lineage from the raw table to the marts, in your browser.
