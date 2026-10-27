resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_project_service" "bigquery_api" {
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_id" "ingest_suffix" {
  byte_length = 4 # Generates 4 random bytes (results in 8 hex characters)
}

resource "google_storage_bucket" "default" {
  name                        = "${var.raw_ingest_bucket_name}_${random_id.ingest_suffix.hex}"
  location                    = "US"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  force_destroy = true
}

resource "google_bigquery_dataset" "raw" {
  dataset_id                  = "${var.raw_ingest_dataset_name}_${random_id.ingest_suffix.hex}"
  friendly_name               = "Raw Ingestion Data"
  description                 = "Raw Polk County sales data"
  location                    = "US"
  default_table_expiration_ms = null

  # Ensures Terraform enables the API before attempting to create the dataset
  depends_on = [
    google_project_service.bigquery_api,
    google_storage_bucket.default
  ]

  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "sales_raw" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = var.raw_ingest_table_name
  deletion_protection = false # Set to true in prod to prevent accidental terraform destroy
  # No schema here: load_raw_sales in ingest.py sets every CSV column as a STRING.

  labels = {
    data_tier = "raw"
  }

  depends_on = [
    google_bigquery_dataset.raw
  ]
}

# 3. Create the BigQuery Table
resource "google_bigquery_table" "sales_raw_logs" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = var.raw_ingest_logs_table_name
  deletion_protection = false # Set to true in prod to prevent accidental terraform destroy
  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp of ingestion record"
    },
    {
      name        = "status"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Status of ingestion data"
    },
    {
      name        = "source"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "The source URL being ingested"
    },
    {
      name        = "destination"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Where the source URL is being ingested to"
    },
    {
      name        = "message"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Any additional message from the logger, if applicable"
    },
  ])

  time_partitioning {
    type  = "DAY"
    field = "timestamp" # Partitions data yearly based on this column
  }

  labels = {
    data_tier = "raw"
  }

  depends_on = [
    google_bigquery_dataset.raw
  ]
}

locals {
  # One dataset per dbt folder. The names must match the +schema settings in dbt/dbt_project.yml.
  dbt_datasets = {
    seeds              = "Lookup tables loaded from dbt seeds"
    staging            = "dbt staging models: typed and cleaned raw sales data"
    staging_audit      = "Failing rows stored by staging tests"
    intermediate       = "dbt intermediate models"
    intermediate_audit = "Failing rows stored by intermediate tests"
    marts_dims         = "Dimension tables"
    marts_dims_audit   = "Failing rows stored by dimension tests"
    marts_facts        = "Fact tables"
    marts_facts_audit  = "Failing rows stored by fact tests"
    marts_bridge       = "Bridge tables from parcel groups to their parcels"
    marts_bridge_audit = "Failing rows stored by bridge tests"
    marts_views        = "Views for analysis and reporting"
    marts_views_audit  = "Failing rows stored by view tests"
  }
}

# Terraform creates and destroys the datasets; dbt creates and replaces the tables inside them.
resource "google_bigquery_dataset" "dbt" {
  for_each    = local.dbt_datasets
  dataset_id  = each.key
  description = each.value
  location    = google_bigquery_dataset.raw.location

  depends_on = [
    google_project_service.bigquery_api,
  ]

  delete_contents_on_destroy = true
}
