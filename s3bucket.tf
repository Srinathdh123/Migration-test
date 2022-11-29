# Upload index file
resource "aws_s3_bucket_object" "object" {
  bucket = var.s3_bucket
  key    = "index.hmtl"
  source = "index.html"
  etag   = filemd5("index.html")

}