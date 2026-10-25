
import json
from pathlib import Path
from datetime import datetime
from time import sleep
from google.cloud import storage
import google.auth
from google.cloud import bigquery
import hashlib
import requests
import base64
import io
from logger import Logger

DEFAULT_GCP_CREDENTIALS_PATH = Path('~/.config/gcloud/application_default_credentials.json').expanduser()

OUTPUTS_FILE_NAME = 'outputs.json'
MIN_YEAR = 1990
MAX_YEAR = datetime.now().year

# Number of seconds to wait per try
RETRIES = [5, 25, 60]

HEADERS = [
    'jurisdiction', 'nbhd', 'pocket', 'dp', 'gp', 'sale_date', 'book', 'pg', 'instrument', 'price', 'address', 'zip', 'seller', 'buyer', 'land_full', 'bldg_full', 'total_full', 'quality1', 'quality2', 'analysis_quality', 'dps', 'gps', 'land_sf', 'land_acres', 'occupancy', 'residence_type', 'bldg_style', 'exterior_wall_type', 'percent_brick', 'roof_type', 'roof_material', 'main_living_area', 'upper_living_area', 'fin_attic_area', 'total_living_area', 'unfin_attic_area', 'foundation', 'basement_area', 'fin_bsmt_area_tot', 'bsmt_walkout', 'bsmt_gar_capacity', 'att_garage_area', 'garage_brick', 'open_porch_area', 'enclose_porch_area', 'patio_area', 'deck_area', 'canopy_area', 'veneer_area', 'carport_area', 'fin_bsmt_area1', 'fin_bsmt_qual1', 'fin_bsmt_area2', 'fin_bsmt_qual2', 'bathrooms', 'toilet_rooms', 'extra_fixtures', 'whirlpools', 'hottubs', 'saunas', 'fireplaces', 'bedrooms', 'rooms', 'families', 'year_built', 'year_remodel', 'eff_year_built', 'condition', 'grade', 'heating', 'air_conditioning', 'percent_complete', 'condo_fin_liv_area', 'condo_year_built', 'detached_structs', 'platname', 'legal_all_parcels', 'school_district', 'initial_entry_date', 'yr'
]

TIMESTAMP_NOW = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
LOG_DEST = f"logs/ingest-logs-{TIMESTAMP_NOW}.csv"
ingest_logger = Logger(LOG_DEST)

def parse_outputs_json():
    """
        Returns the outputs json file if the file was found and successfully was decoded,
        returns none otherwise.
    """

    file_path = Path(f"./{OUTPUTS_FILE_NAME}")

    if not file_path.is_file():
        print(f"{OUTPUTS_FILE_NAME} does not exist. Run 'terraform plan', 'terraform apply', and './scripts/save_outputs.sh' to generate {OUTPUTS_FILE_NAME}.")
        return None
    
    # Open and parse the JSON file
    with open(file_path, 'r') as file:
        try:
            data = json.load(file)
            return data
        except json.JSONDecodeError as e:
            print(f"Failed to decode JSON: {e.msg}")
    
    return None

def get_gcp_file_blob(bucket_name, file_path):
    """Get blob of gcp file. Returns none is file doesn't exist."""

    # 1. Initialize the Google Cloud Storage client
    credentials, project_id = google.auth.default()
    storage_client = storage.Client(credentials=credentials, project=project_id)
    
    # 2. Get a reference to the bucket
    bucket = storage_client.bucket(bucket_name)
    
    # 3. Create a blob object representing the file path (object name)
    blob = bucket.blob(file_path)
    
    # 4. Check if the blob exists in the cloud bucket
    if not blob.exists():
        return None
    
    return bucket.get_blob(file_path)

def download_csv_file(url, retries):
    """
        Return CSV string of the requested CSV file if download is a success. 
        Returns None otherwise.
    """
    r = 0
   
    while (r < len(retries)):
        try:
            ingest_logger.log('DOWNLOADING', url, "", f"Retry: {r}")
            response = requests.get(url)
            # Ensure the download was successful
            response.raise_for_status()

            csv_file = io.StringIO(response.text)
            csv_string = csv_file.getvalue()
            ingest_logger.log('DOWNLOADED', url, "", f"Retry: {r}")
            return csv_string
        except:
            ingest_logger.log('DOWNLOAD FAILED', url, "", f"Failed on retry: {r}")
            sleep(retries[r])
            r += 1
    
    return None

def ingest(source_url, filename, bucket, retries):
    """
        Ingests polk county sales data into the provided GCP bucket.

        Returns whether to refresh the bigquery table.
    """

    source = f"{source_url}/{filename}"
    dest =f"gs://{bucket.name}/{filename}"

    downloaded_file = download_csv_file(source, retries)
    if downloaded_file is None:
        ingest_logger.log('DOWNLOAD FAILED', source, "", f"There was an error downloading the CSV from {source}.")
        return False
    
    ingest_logger.log('DOWNLOAD SUCCESS', source)
    ingest_logger.log('ENCODING SOURCE', source)
    encoded = downloaded_file.encode("utf-8")

    downloaded_md5_hash = base64.b64encode(
        hashlib.md5(encoded).digest()
    ).decode("ascii")
    ingest_logger.log('ENCODED SOURCE', source, "", f"Encoded: {downloaded_md5_hash}")

    ingest_logger.log('CHECKING FILE EXISTANCE', "", dest, f"Checking if {filename} is in GCP bucket: {bucket.name}...")
    gcp_file = get_gcp_file_blob(bucket.name, filename)
    
    if gcp_file is not None:
        ingest_logger.log('FILE EXISTS', "", dest, f"File {filename} exists in {bucket.name}")
        ingest_logger.log('CHECKING HASHES', source, dest, f"Source hash: {downloaded_md5_hash}, GCP hash: {gcp_file.md5_hash}")
        if downloaded_md5_hash == gcp_file.md5_hash:
            ingest_logger.log('SKIP INGEST', source, dest, "file hashes were equal")
            return False
        else:
            ingest_logger.log('UPDATING FILE', source, dest, "Updating file in GCS bucket")
            gcp_file.upload_from_string(
                data=downloaded_file, 
                content_type='text/csv',
                checksum='md5'
            )
            ingest_logger.log('FILE UPDATED', source, dest, "File in GCS bucket updated")
    else:
        ingest_logger.log('FILE DOES NOT EXIST', "", dest, f"File {filename} does not exist in {bucket.name}.")
        ingest_logger.log('UPLOADING FILE', source, dest, f"Uploading to GCP bucket from source")

        gcp_file = bucket.blob(filename)
        gcp_file.upload_from_string(
            data=downloaded_file, 
            content_type='text/csv',
            checksum='md5'
        )
        ingest_logger.log('FILE UPLOADED', source, dest, f"File uploaded to GCP bucket")

    
    return True

def load_raw_sales(project_id, dataset_id, bucket, headers, sales_table_name):
    client = bigquery.Client(project=project_id)

    table_id = f"{project_id}.{dataset_id}.{sales_table_name}"
    source_uri = f"gs://{bucket.name}/*.csv"

    ingest_logger.log('PULLING CSV DATA INTO TABLE', source_uri, table_id)
    config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        schema=[
            bigquery.SchemaField(column, "STRING", mode="NULLABLE")
            for column in headers
        ],
        skip_leading_rows=1,
        allow_quoted_newlines=True,
        max_bad_records=0,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    job = client.load_table_from_uri(
        source_uri,
        table_id,
        job_config=config,
        location="US",
    )
    job.result()  # Wait for completion and raise on failure.

    table = client.get_table(table_id)
    ingest_logger.log('CSV DATA PULLED INTO TABLE', source_uri, table_id, f"Loaded {table.num_rows:,} rows into {table_id}")

def load_raw_log_data(project_id, dataset_id, sales_logs_table_name, ingest_logger):
    client = bigquery.Client(project=project_id)

    table_id = f"{project_id}.{dataset_id}.{sales_logs_table_name}"
    ingest_logger.log('PULLING CSV LOG DATA INTO TABLE', ingest_logger.file.name, table_id)

    # Use the schema Terraform gave the table, so its types, modes and descriptions are kept.
    table = client.get_table(table_id)
    config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        schema=table.schema,
        skip_leading_rows=1,
        allow_quoted_newlines=True,
        max_bad_records=0,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )

    # The logger's handle is write-only text, but uploads need a binary read handle.
    with open(ingest_logger.file.name, "rb") as log_file:
        job = client.load_table_from_file(
            log_file,
            table_id,
            job_config=config
        )
        job.result()  # Wait for completion and raise on failure.

    ingest_logger.log('CSV LOG DATA PULLED INTO TABLE', ingest_logger.file.name, table_id, f"Loaded {job.output_rows:,} rows into {table_id}")


def main():
    outputs = parse_outputs_json()
    if outputs is None:
        return

    # Assume all keys and values exist
    source_url = outputs["raw_ingest_source_url"]['value']
    gcp_bucket_name = outputs["gcp_bucket_raw_ingest_id"]['value']
    gcp_project_id = outputs["gcp_project_id"]['value']
    gcp_dataset_id = outputs["gcp_bigquery_raw_ingest_id"]['value']
    gcp_ingest_table_name = outputs['gcp_bigquery_sales_raw_table_name']['value']
    gcp_ingest_logs_table_name = outputs['gcp_bigquery_sales_raw_logs_table_name']['value']
    storage_client = storage.Client()
    
    # Get the bucket
    bucket = storage_client.bucket(gcp_bucket_name)
    
    

    # Ingest yearly csv data. Reload BigQuery if any year's file was new or changed.
    should_refresh = False
    for y in range(MIN_YEAR, MAX_YEAR + 1):
        filename = f"{y}.csv"
        if ingest(source_url, filename, bucket, RETRIES):
            should_refresh = True

    if should_refresh:
        load_raw_sales(gcp_project_id, gcp_dataset_id, bucket, HEADERS, gcp_ingest_table_name)

    load_raw_log_data(gcp_project_id, gcp_dataset_id, gcp_ingest_logs_table_name, ingest_logger)

if __name__ == "__main__":
    main()
