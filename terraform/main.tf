module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.1"

  bucket = "intelligent-urban-traffic-data-engineering"
  acl    = "private"

  tags = {
    Name        = "Intelligent-Urban-Traffic-Data-Engineering"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "bronze_folder" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "bronze/"
  source = "/dev/null"
}

resource "aws_s3_object" "silver_folder" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "silver/"
  source = "/dev/null"
}

resource "aws_s3_object" "gold_folder" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "gold/"
  source = "/dev/null"
}