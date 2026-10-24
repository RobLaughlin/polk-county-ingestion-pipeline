output "gcp_project_id" {
  value       = var.gcp_project_id
  description = "The GCP project ID"
}

output "gcp_bigquery_raw_ingest_id" {
  value       = google_bigquery_dataset.raw.dataset_id
  description = "The GCP BigQuery raw dataset ID"
}

output "gcp_bigquery_sales_raw_table_name" {
  value       = var.raw_ingest_table_name
  description = "The table where the raw ingest data is stored"
}

output "gcp_bigquery_sales_raw_logs_table_name" {
  value       = var.raw_ingest_logs_table_name
  description = "The table where the logs for the raw ingestion process is stored"
}

output "gcp_bigquery_transform_id" {
  # dbt's default dataset in profiles.yml, for any model without a +schema folder mapping
  value       = google_bigquery_dataset.dbt["staging"].dataset_id
  description = "The GCP BigQuery dataset ID used as dbt's default dataset in profiles.yml"
}

output "gcp_bucket_raw_ingest_id" {
  value       = google_storage_bucket.default.id
  description = "The GCP raw storage bucket ID"
}

output "raw_ingest_source_url" {
  value       = var.raw_ingest_source_url
  description = "The source URL for where to pull the raw CSV sales data"
}
