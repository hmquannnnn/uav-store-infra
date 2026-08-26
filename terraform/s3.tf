# S3 thay MinIO. FE hiển thị ảnh bằng URL path-style ghép thẳng (file_path đã chứa
# bucket) → cần GetObject public. Upload qua presigned URL từ browser → cần CORS.
# Prod chuẩn thì CloudFront + OAC thay vì mở bucket — demo chấp nhận trade-off này.

resource "aws_s3_bucket" "data" {
  bucket        = "${var.project}-data-${data.aws_caller_identity.me.account_id}"
  force_destroy = true # destroy xoá được cả khi còn object (teardown trong ngày)
  tags          = { Name = "${var.project}-data" }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Nới đúng mức: vẫn chặn ACL public, nhưng cho phép bucket policy public-read bên dưới.
resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadObjects"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"] # CHỈ đọc object; list/write vẫn qua IAM
      Resource  = ["${aws_s3_bucket.data.arn}/*"]
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.data]
}

# CORS cho upload PUT bằng presigned URL từ browser (origin = domain FE).
resource "aws_s3_bucket_cors_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_origins = [
      "https://${var.domain}",
      "https://www.${var.domain}",
      "http://localhost:3000", # dev local test upload
    ]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}
