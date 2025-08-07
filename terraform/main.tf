provider "aws" {
   region = "us-east-1"
}

resource "aws_s3_bucket" "cicd_terraform" {
    bucket = var.bucket_name

    tags = {
        Name = var.bucket_name
    }
    force_destroy = true
}