import json
import boto3
import pandas as pd
from io import StringIO

s3 = boto3.client("s3")

bucket_name = "intelligent-urban-traffic-data-engineering"

source_dir = "bronze/"
target_dir = "silver/"


def lambda_handler(event, context):
    result = s3.list_objects(Bucket=bucket_name, Prefix=source_dir)

    for item in result["Contents"]:
        file_name = item["Key"]
        obj = s3.get_object(Bucket=bucket_name, Key=file_name)

        data = obj["Body"].read().decode("utf-8")

        df = pd.read_csv(StringIO(data))

        df = df.dropna()

        csv_buffer = StringIO()
        df.to_csv(csv_buffer, index=False)
        processed_data = csv_buffer.getvalue()

        new_file_name = file_name.replace(source_dir, target_dir)
        s3.put_object(Body=processed_data, Bucket=bucket_name, Key=new_file_name)

    return {
        "statusCode": 200,
        "body": json.dumps("Data processed successfully!")
    }
