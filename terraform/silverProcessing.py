import json
import boto3
import pandas as pd
from io import StringIO

s3 = boto3.client("s3")

bucket_name = "intelligent-urban-traffic-data-engineering"

source_dir = "silver/"
target_dir = "gold/"

def lambda_handler(event, context):
    result = s3.list_objects(Bucket=bucket_name, Prefix=source_dir)

    for item in result["Contents"]:
        file_name = item["Key"]
        obj = s3.get_object(Bucket=bucket_name, Key=file_name)

        data = obj["Body"].read().decode("utf-8")

        df = pd.read_csv(StringIO(data))

        num_vehicles = df[df["Entity_Type"] == "Vehicle"].shape[0]
        num_traffic_lights = df[df['Entity_Type'] == 'Traffic_Light'].shape[0]
        num_sensors = df[df['Entity_Type'] == 'Sensor'].shape[0]
        num_cameras = df[df['Entity_Type'] == 'Camera'].shape[0]

        avg_vehicles_per_traffic_light = df[df['Entity_Type'] == 'Vehicle_Traffic_Light'][
            "Vehicle_ID"].nunique() / num_traffic_lights
        avg_vehicles_per_sensor = df[df['Entity_Type'] == 'Vehicle_Sensor']['Vehicle_ID'].nunique() / num_sensors

        df_aggregated = pd.DataFrame({
            'Metric': ['Number of Vehicles', 'Number of Traffic Lights', 'Number of Sensors', 'Number of Cameras',
                       'Avg Vehicles per Traffic Light', 'Avg Vehicles per Sensor'],
            'Value': [num_vehicles, num_traffic_lights, num_sensors, num_cameras, avg_vehicles_per_traffic_light,
                      avg_vehicles_per_sensor]
        })

        csv_buffer = StringIO()
        df_aggregated.to_csv(csv_buffer, index=False)
        processed_data = csv_buffer.getvalue()

        new_file_name = file_name.replace(source_dir, target_dir)

        s3.put_object(Body=processed_data, Bucket=bucket_name, Key=new_file_name)

    return {
        'statusCode': 200,
        'body': json.dumps('Data processed successfully!')
    }
