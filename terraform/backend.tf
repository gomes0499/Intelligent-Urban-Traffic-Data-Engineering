# Configure the backend to store state in S3
terraform {
  backend "s3" {
    bucket = "gomes-tf-state"
    key = "intelligent-urban-traffic-data-engineering-tf-state"
    region = "us-east-1"
  }
}