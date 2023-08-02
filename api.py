import boto3
import json
from faker import Faker

fake = Faker()

kinesis_client = boto3.client("kinesis", region_name="us-east-1")
stream_name = 'kinesis-datastream-intelligent-urban-traffic-data-engineering'


def generate_vehicle():
    return {
        "Vehicle_ID": fake.uuid4(),
        "License_Plate": fake.license_plate(),
        "Vehicle_Type": fake.random_element(elements=('Car', 'Bus', 'Truck')),
        "Entry_Time": str(fake.date_time_this_year()),
        "Exit_Time": str(fake.date_time_this_year())
    }


def generate_traffic_light():
    return {
        "Traffic_Light_ID": fake.uuid4(),
        "Location": fake.address(),
        "Status": fake.random_element(elements=('Green', 'Red', 'Yellow'))
    }


def generate_sensor():
    return {
        "Sensor_ID": fake.uuid4(),
        "Location": fake.address(),
        "Traffic_count": fake.random_int(min=0, max=1000),
    }


def generate_camera():
    return {
        "Camera_ID": fake.uuid4(),
        "Location": fake.address(),
        "Last_Image_Captured": fake.file_name(extension="jpg")
    }


def generate_vehicle_association(entity_name, entity_id):
    return {
        "Vehicle_ID": fake.uuid4(),
        f"{entity_name}_ID": entity_id,
        "Timestamp": str(fake.date_time_this_year())
    }


def send_to_kinesis(record):
    kinesis_client.put_record(
        StreamName=stream_name,
        Data=json.dumps(record),
        PartitionKey="partitionkey"
    )


if __name__ == "__main__":
    vehicle = generate_vehicle()
    traffic_light = generate_traffic_light()
    sensor = generate_sensor()
    camera = generate_camera()

    send_to_kinesis(vehicle)
    send_to_kinesis(traffic_light)
    send_to_kinesis(sensor)
    send_to_kinesis(camera)
    send_to_kinesis(generate_vehicle_association("Traffic_Light", traffic_light["Traffic_Light_ID"]))
    send_to_kinesis(generate_vehicle_association("Sensor", sensor["Sensor_ID"]))
    send_to_kinesis(generate_vehicle_association("Camera", camera["Camera_ID"]))
