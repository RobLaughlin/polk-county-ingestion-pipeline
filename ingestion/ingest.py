
import json
from pathlib import Path
from datetime import datetime
from time import sleep
from google.cloud import storage
import google.auth
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
    response = requests.get(url)

    while (r < len(retries)):
        try:
            # Ensure the download was successful
            response.raise_for_status()

            csv_file = io.StringIO(response.text)
            csv_string = csv_file.getvalue()
            return csv_string
        except:
            sleep(retries[r])
            r += 1
    
    return None

def main():
    outputs = parse_outputs_json()
    if outputs is None:
        return

    # Assume all keys and values exist
    source_url = outputs["raw_ingest_source_url"]['value']
    gcp_bucket_name = outputs["gcp_bucket_raw_ingest_id"]['value']
    storage_client = storage.Client()
    
    # Get the bucket
    bucket = storage_client.bucket(gcp_bucket_name)

    for y in range(MIN_YEAR, MAX_YEAR + 1):
        filename = f"{y}.csv"
        source = f"{source_url}/{filename}"

        print(f"Downlading from source: {source}")
       

        downloaded_file = download_csv_file(source, RETRIES)
        if downloaded_file is None:
            print(f"There was an error downloading the CSV from {source}.")
            print("Moving on to the next file...")
            continue
        
        print(f"File {filename} successfully downloaded.")
        encoded = downloaded_file.encode("utf-8")

        downloaded_md5_hash = base64.b64encode(
            hashlib.md5(encoded).digest()
        ).decode("ascii")
        
        print(f"Checking if {filename} is in GCP bucket: {gcp_bucket_name}...")
        gcp_file = get_gcp_file_blob(gcp_bucket_name, filename)

        if gcp_file is not None:
            print(downloaded_md5_hash, gcp_file.md5_hash)
            print(f"File {filename} exists in {gcp_bucket_name}")
            if downloaded_md5_hash == gcp_file.md5_hash:
                print(f"Hashes are equal, no need to update. Skipping ingestion of {filename}\n")
            else:
                print(f"Hashes are not equal, updating file {filename} in {gcp_bucket_name}...")
                gcp_file.upload_from_string(
                    data=downloaded_file, 
                    content_type='text/csv',
                    checksum='md5'
                )
                print(f"{filename} uploaded to {gcp_bucket_name}\n")
        else:
            print(f"File {filename} does not exist in {gcp_bucket_name}.")
            print(f"Uploading {filename} to {gcp_bucket_name}...")
            gcp_file = bucket.blob(filename)
            gcp_file.upload_from_string(
                data=downloaded_file, 
                content_type='text/csv',
                checksum='md5'
            )
            print(f"{filename} uploaded to {gcp_bucket_name}\n")

if __name__ == "__main__":
    main()
