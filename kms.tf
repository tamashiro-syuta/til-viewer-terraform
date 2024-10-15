data "aws_iam_policy_document" "til_viewer_app_kms_key" {
  version = "2012-10-17"
  # デフォルトキーポリシー
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  # OACで必要なキーポリシー
  statement {
    sid    = "AllowCloudFrontServicePrincipalSSE-KMS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.til_viewer_app.arn]
    }
  }
}

resource "aws_kms_key" "til_viewer_app_kms_key" {
  description         = "KMS key for CloudFront and S3 integration in TIL Viewer App"
  policy              = data.aws_iam_policy_document.til_viewer_app_kms_key.json
  enable_key_rotation = true
  tags = {
    Name = local.github_repository
  }
}

resource "aws_kms_alias" "til_viewer_app_kms_key" {
  name          = "alias/til-viewer-app-kms-key"
  target_key_id = aws_kms_key.til_viewer_app_kms_key.key_id
}
