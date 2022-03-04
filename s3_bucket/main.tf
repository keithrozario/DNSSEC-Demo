variable bucket_prefix {}
resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
}


resource "aws_s3_bucket_object" "index" {
  key        = "index.html"
  bucket     = aws_s3_bucket.this.id
  source     = "./s3_bucket/index.html"
  force_destroy = true
  content_type = "text/html"
}



output bucket_name {
    value = aws_s3_bucket.this.id
}