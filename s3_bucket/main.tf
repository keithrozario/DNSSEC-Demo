resource "aws_s3_bucket" "this" {
  bucket_prefix = "dnssec-demo"
}

resource "aws_s3_object" "index" {
  key                    = "index.html"
  bucket                 = aws_s3_bucket.this.id
  source                 = "./s3_bucket/index.html"
  server_side_encryption = "aws:kms"
}

output bucket_name {
    value = aws_s3_bucket.this.id
}