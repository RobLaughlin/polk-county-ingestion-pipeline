
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

DEFAULT_GCP_CREDENTIALS_PATH = Path('~/.config/gcloud/application_default_credentials.json').expanduser()

OUTPUTS_FILE_NAME = 'outputs.json'
MIN_YEAR = 1990
MAX_YEAR = datetime.now().year

# Number of seconds to wait per try
RETRIES = [5, 25, 60]

HEADERS = [
    'jurisdiction', 'nbhd', 'pocket', 'dp', 'gp', 'sale_date', 'book', 'pg', 'instrument', 'price', 'address', 'zip', 'seller', 'buyer', 'land_full', 'bldg_full', 'total_full', 'quality1', 'quality2', 'analysis_quality', 'dps', 'gps', 'land_sf', 'land_acres', 'occupancy', 'residence_type', 'bldg_style', 'exterior_wall_type', 'percent_brick', 'roof_type', 'roof_material', 'main_living_area', 'upper_living_area', 'fin_attic_area', 'total_living_area', 'unfin_attic_area', 'foundation', 'basement_area', 'fin_bsmt_area_tot', 'bsmt_walkout', 'bsmt_gar_capacity', 'att_garage_area', 'garage_brick', 'open_porch_area', 'enclose_porch_area', 'patio_area', 'deck_area', 'canopy_area', 'veneer_area', 'carport_area', 'fin_bsmt_area1', 'fin_bsmt_qual1', 'fin_bsmt_area2', 'fin_bsmt_qual2', 'bathrooms', 'toilet_rooms', 'extra_fixtures', 'whirlpools', 'hottubs', 'saunas', 'fireplaces', 'bedrooms', 'rooms', 'families', 'year_built', 'year_remodel', 'eff_year_built', 'condition', 'grade', 'heating', 'air_conditioning', 'percent_complete', 'condo_fin_liv_area', 'condo_year_built', 'detached_structs', 'platname', 'legal_all_parcels', 'school_district', 'initial_entry_date', 'yr'
]

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
            response = requests.get(url)
            # Ensure the download was successful
            response.raise_for_status()

            csv_file = io.StringIO(response.text)
            csv_string = csv_file.getvalue()
            return csv_string
        except:
            sleep(retries[r])
            r += 1
    
    return None

def ingest(source_url, filename, bucket, retries):
    """
        Ingests polk county sales data into the provided GCP bucket.

        Returns whether to refresh the bigquery table.
    """

    source = f"{source_url}/{filename}"
    print(f"Downlading from source: {source}")
    
    downloaded_file = download_csv_file(source, retries)
    if downloaded_file is None:
        print(f"There was an error downloading the CSV from {source}.")
        return False
    
    print(f"File {filename} successfully downloaded.")
    encoded = downloaded_file.encode("utf-8")

    downloaded_md5_hash = base64.b64encode(
        hashlib.md5(encoded).digest()
    ).decode("ascii")
    
    print(f"Checking if {filename} is in GCP bucket: {bucket.name}...")
    gcp_file = get_gcp_file_blob(bucket.name, filename)

    if gcp_file is not None:
        print(f"File {filename} exists in {bucket.name}")
        if downloaded_md5_hash == gcp_file.md5_hash:
            print(f"Hashes are equal, no need to update. Skipping ingestion of {filename}\n")
            return False
        else:
            print(f"Hashes are not equal, updating file {filename} in {bucket.name}...")
            gcp_file.upload_from_string(
                data=downloaded_file, 
                content_type='text/csv',
                checksum='md5'
            )
            print(f"{filename} uploaded to {bucket.name}\n")
    else:
        print(f"File {filename} does not exist in {bucket.name}.")
        print(f"Uploading {filename} to {bucket.name}...")
        gcp_file = bucket.blob(filename)
        gcp_file.upload_from_string(
            data=downloaded_file, 
            content_type='text/csv',
            checksum='md5'
        )
        print(f"{filename} uploaded to {bucket.name}\n")
    
    return True

def load_raw_sales(project_id, dataset_id, bucket, headers):
    client = bigquery.Client(project=project_id)

    table_id = f"{project_id}.{dataset_id}.sales_raw"
    source_uri = f"gs://{bucket.name}/*.csv"

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
    print(f"Loaded {table.num_rows:,} rows into {table_id}")

def main():
    outputs = parse_outputs_json()
    if outputs is None:
        return

    # Assume all keys and values exist
    source_url = outputs["raw_ingest_source_url"]['value']
    gcp_bucket_name = outputs["gcp_bucket_raw_ingest_id"]['value']
    gcp_project_id = outputs["gcp_project_id"]['value']
    gcp_dataset_id = outputs["gcp_bigquery_raw_ingest_id"]['value']
    storage_client = storage.Client()
    
    # Get the bucket
    bucket = storage_client.bucket(gcp_bucket_name)
    
    # Ingest yearly csv data
    should_refresh = False
    for y in range(MIN_YEAR, MAX_YEAR + 1):
        filename = f"{y}.csv"
        should_refresh = ingest(source_url, filename, bucket, RETRIES) or False

    if should_refresh:
        print("Refreshing table...")
        load_raw_sales(gcp_project_id, gcp_dataset_id, bucket, HEADERS)
    else:
        print("No need to refresh, all sources are equal.")
    
if __name__ == "__main__":
    main()
