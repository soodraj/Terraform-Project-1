#Terraform template for SNS SQS

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "=3.30.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
}

resource "random_string" "random" {
  length = 15
  special = false
  upper = false
}

resource "aws_s3_bucket" "bucket" {
  bucket = "upload-bucket"
  acl    = "private"
}

resource "aws_sqs_queue" "queue" {
  name = "upload-queue"
  delay_seconds = 60
  max_message_size = 8192
  message_retention_seconds	= 172800
  receive_wait_time_seconds = 15
}

resource "aws_sqs_queue_policy" "notif_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "1",
  "Statement": [
    {
      "Sid":"Queue1_SendMessage",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.upload-bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notif" {
  bucket = aws_s3_bucket.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
