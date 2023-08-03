# ---------------- LOCAL VARIABLES ----------------

locals {
  project     = "intelligent-urban-traffic-data-engineering"
  environment = "dev"
}

# ---------------- KINESIS STREAM/FIREHOSE INGESTION ----------------
module "kinesis-stream" {

  source  = "rodrigodelmonte/kinesis-stream/aws"
  version = "v2.0.3"

  name                      = "kinesis-datastream-${local.project}"
  shard_count               = 1
  retention_period          = 24
  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
  enforce_consumer_deletion = false
  encryption_type           = "KMS"
  kms_key_id                = "alias/aws/kinesis"
  tags                      = {
    Name = "dev-${local.project}"
  }

}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "kinesis-firehose-${local.project}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = module.kinesis-stream.kinesis_stream_arn
    role_arn           = var.rolearn
  }

  extended_s3_configuration {
    role_arn   = var.rolearn
    bucket_arn = module.s3_bucket.s3_bucket_arn
    prefix     = "bronze/"


  }
}

# ---------------- S3 DATA LAKE BRONZE/SILVER/GOLD LAYER ----------------
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.1"

  bucket = "intelligent-urban-traffic-data-engineering"

  tags = {
    Name        = "Intelligent-Urban-Traffic-Data-Engineering"
    Environment = local.environment
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

# ---------------- LAMBDA/PROCESSING & QUALITY BRONZE TO SILVER LAYER ----------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/bronzeProcessing.py"
  output_path = "${path.module}/bronzeProcessing.zip"
}

resource "aws_lambda_function" "s3_processing" {
  function_name = "lambda_bronze_silver"
  role          = var.rolearn
  handler       = "lambda_function.handler"
  runtime       = "python3.8"
  filename      = data.archive_file.lambda_zip.output_path
}

resource "aws_lambda_permission" "s3_invocation" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processing.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification_bronze_silver" {
  bucket = module.s3_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processing.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "bronze/"
  }

  depends_on = [aws_lambda_permission.s3_invocation]
}

# ---------------- LAMBDA/PROCESSING & QUALITY SILVER TO GOLD LAYER ----------------

data "archive_file" "lambda_silver_gold_zip" {
  type        = "zip"
  source_file = "${path.module}/silverProcessing.py"
  output_path = "${path.module}/silverProcessing.zip"
}

resource "aws_lambda_function" "s3_processing_silver_gold" {
  function_name = "lambdaSilverGold"
  role          = var.rolearn
  handler       = "lambda_function.handler"
  runtime       = "python3.8"
  filename      = data.archive_file.lambda_silver_gold_zip.output_path
}

resource "aws_lambda_permission" "s3_invocation_silver_gold" {
  statement_id  = "AllowS3InvocationSilverGold"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processing_silver_gold.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket.s3_bucket_arn
}


resource "aws_s3_bucket_notification" "bucket_notification_silver_gold" {
  bucket = module.s3_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processing_silver_gold.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "silver/"
  }

  depends_on = [aws_lambda_permission.s3_invocation_silver_gold]
}


