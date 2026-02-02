from google.cloud import storage
from google.cloud import aiplatform
import functions_framework
import vertexai
from vertexai.generative_models import GenerativeModel, Part
import os
import pymysql
import pymysql.cursors

PROJECT_ID = "REPLACE_WITH_YOUR_PROJECT_ID"
GEMINI_MODEL = "gemini-2.5-flash"
DEFAULT_PROMPT = "Generate a caption for this image: "

def gemini_describe_image_from_gcs(gcs_url, image_prompt=DEFAULT_PROMPT):
    """
    Generates a description for an image stored in GCS using Gemini.

    Args:
        gcs_url (str): The GCS URI of the image (e.g., "gs://bucket/image.png").
        image_prompt (str): The prompt to send to the Gemini model.

    Returns:
        str: The generated image caption, or None if an error occurs.
    """
    print(f"Initializing Vertex AI for project {PROJECT_ID}...")
    vertexai.init(project=PROJECT_ID, location="us-central1")
    print(f"Loading Gemini model: {GEMINI_MODEL}...")
    model = GenerativeModel(GEMINI_MODEL)

    image_part = Part.from_uri(gcs_url, mime_type="image/png") # Assumes PNG, adjust if other formats are used

    try:
        print(f"Generating content for image {gcs_url} with prompt: '{image_prompt}'")
        response = model.generate_content([image_part, image_prompt])
        print("Successfully received response from Gemini.")
        return response.text
    except Exception as e:
        print(f"Error generating content from Gemini: {e}")
        return None

def update_db_with_description(image_filename, caption, db_user, db_pass, db_host, db_name):
    """
    Updates the image description in the database.

    Args:
        image_filename (str): The filename of the image to update.
        caption (str): The caption to add to the image's record.
        db_user (str): Database user.
        db_pass (str): Database password.
        db_host (str): Database host (can be an IP address or a Unix socket path).
        db_name (str): Database name.
    """
    try:
        print(f"Connecting to database '{db_name}' at host '{db_host}'...")
        # For Cloud SQL, the host is often a socket path for private connections
        if db_host.startswith('/'):
             print("Connecting via Unix socket.")
             conn = pymysql.connect(user=db_user, password=db_pass,
                                   unix_socket=db_host, db=db_name,
                                   cursorclass=pymysql.cursors.DictCursor)
        else:
            print("Connecting via TCP.")
            conn = pymysql.connect(host=db_host, user=db_user, password=db_pass,
                                   db=db_name, cursorclass=pymysql.cursors.DictCursor)
        print("Database connection successful.")

        with conn.cursor() as cursor:
            print(f"Executing update for filename: {image_filename}")
            sql = "UPDATE images SET description = %s WHERE filename = %s"
            cursor.execute(sql, (caption, image_filename))
        conn.commit()
        print(f"Successfully updated description for {image_filename}")
    except pymysql.MySQLError as e:
        print(f"Error during database operation: {e}")
    finally:
        if 'conn' in locals() and conn.open:
            print("Closing database connection.")
            conn.close()

@functions_framework.cloud_event
def generate_caption(cloud_event):
    """
    Cloud Function triggered by a GCS event to generate a caption for a new image
    and update the database.

    Args:
        cloud_event (cloudevent.CloudEvent): The event payload.
            The `data` attribute will contain the GCS event data.
    """
    data = cloud_event.data
    bucket = data["bucket"]
    name = data["name"]

    gcs_uri = f"gs://{bucket}/{name}"
    print(f"Processing file: {gcs_uri}")

    # Generate a caption for the image using Gemini
    caption = gemini_describe_image_from_gcs(gcs_uri)

    if caption:
        print(f"Generated caption: {caption}")
        # Retrieve database configuration from environment variables
        db_user = os.environ.get("DB_USER")
        db_pass = os.environ.get("DB_PASS")
        db_host = os.environ.get("DB_HOST")
        db_name = os.environ.get("DB_NAME")

        if not all([db_user, db_pass, db_host, db_name]):
            print("Error: Database environment variables are not set.")
            return

        filename = 'uploads/' + name

        update_db_with_description(filename, caption, db_user, db_pass, db_host, db_name)
    else:
        print(f"Could not generate a caption for {gcs_uri}.")