# Polk County Ingestion Pipeline

A local Docker ingestion pipeline for residential sale CSVs published by the
[Polk County Assessor](https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=downloads/res_sales_polk).

Each run provisions infrastructure in an **existing GCP project** with Terraform,
discovers yearly CSVs, downloads them concurrently, and uploads only missing or
changed files to Google Cloud Storage. After all workers finish, it appends a log
batch to BigQuery.

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) version >= 1.2.0 Installed
2. An already existing [GCP Account](https://console.cloud.google.com/freetrial/)
3. [Google Cloud Cli](https://docs.cloud.google.com/sdk/docs/install-sdk) Installed

## Instructions

1. Create a [GCP Project](https://console.cloud.google.com/projectcreate) and make note of the Project ID.
2. Enable the Google Compute Engine API for your project in the [GCP Console](https://console.developers.google.com/apis/library/compute.googleapis.com).
3. Run the following command: `gcloud auth application-default login` . If running on WSL2, append `--no-launch-browser` to the command. These credentials will be saved and used by default in Terraform.
4. `cd` into the `terraform` directory and run `terraform init`.
5. Run `terraform plan` and if everything looks good to you, run `terraform apply` to create the infrastructure. Infrastructure can be destroyed with `terraform destroy`.
