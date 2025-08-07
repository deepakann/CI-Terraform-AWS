output "s3_bucketname" {
    value = aws_s3_bucket.cicd_terraform.id
}