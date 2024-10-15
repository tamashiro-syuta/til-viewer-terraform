# ------------------------------------------------------------
// NOTE: 記事の中で使われている画像を保存するためのS3バケット
# ------------------------------------------------------------
resource "aws_s3_bucket" "til_viewer_images" {
  bucket = "til-viewer-images"
}

# ------------------------------------------------------------
# NOTE: Next.jsのビルド結果を配置するためのS3バケット
# ------------------------------------------------------------
resource "aws_s3_bucket" "til_viewer_app" {
  bucket = "til-viewer-app"
}


# NOTE: サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "til_viewer_app_encryption" {
  bucket = aws_s3_bucket.til_viewer_app.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.til_viewer_app_kms_key.id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# NOTE: ACL無効化
resource "aws_s3_bucket_ownership_controls" "til_viewer_app_bucket_ownership_controls" {
  bucket = aws_s3_bucket.til_viewer_app.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# NOTE: パブリックブロックアクセス(cloudfront経由のみを許可するためパブリックアクセスはできないようにする)
resource "aws_s3_bucket_public_access_block" "til_viewer_app_bucket_public_access_block" {
  bucket = aws_s3_bucket.til_viewer_app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket_policy.til_viewer_app_bucket_policy,
    aws_s3_bucket_ownership_controls.til_viewer_app_bucket_ownership_controls
  ]
}

resource "aws_s3_bucket_policy" "til_viewer_app_bucket_policy" {
  bucket = aws_s3_bucket.til_viewer_app.id
  policy = data.aws_iam_policy_document.til_viewer_app.json
}

data "aws_iam_policy_document" "til_viewer_app" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.til_viewer_app.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.til_viewer_app.arn]
    }
  }
}
