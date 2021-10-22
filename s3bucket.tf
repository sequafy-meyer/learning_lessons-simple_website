data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${data.aws_caller_identity.current.account_id}.website-content"
}

resource "aws_s3_bucket" "website_content" {
  bucket = local.bucket_name

  policy = templatefile("templates/s3_bucket_policy.tpl",{
      bucket_name = local.bucket_name,
      account_id  = data.aws_caller_identity.current.account_id,
      region      = var.region
  })
 
  tags = merge(
    {
      Name = local.bucket_name
    },
    var.tags,
  )

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "index_document" {
  bucket       = aws_s3_bucket.website_content.id
  content_type = "text/html"
  etag         = filemd5("files/index.php")
  key          = "index.php"
  source       = "files/index.php"
}

resource "aws_s3_bucket_object" "functions_document" {
  bucket       = aws_s3_bucket.website_content.id
  content_type = "text/html"
  etag         = filemd5("files/functions.php")
  key          = "functions.php"
  source       = "files/functions.php"
}