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

resource "google_bigquery_dataset" "transform" {
  dataset_id                  = "${var.transform_dataset_name}_${random_id.ingest_suffix.hex}"
  friendly_name               = "Transformed Sales Data"
  description                 = "Polk County staging, intermediate, and mart models managed by dbt"
  location                    = google_bigquery_dataset.raw.location
  default_table_expiration_ms = null

  depends_on = [
    google_project_service.bigquery_api,
  ]

  delete_contents_on_destroy = true
}
