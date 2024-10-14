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

resource "aws_s3_bucket_policy" "til_viewer_app_bucket_policy" {
  bucket = aws_s3_bucket.til_viewer_app.id
  policy = data.aws_iam_policy_document.til_viewer_app.json
}

data "aws_iam_policy_document" "til_viewer_app" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.til_viewer_app.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.til_viewer_app.arn}/*"]
  }
}
