# resource "aws_kms_key" "til_viewer_app_kms_key" {
#   description             = "KMS key for CloudFront and S3 integration in TIL Viewer App"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
# }

# resource "aws_kms_alias" "til_viewer_app_alias" {
#   name          = "alias/til-viewer-app-kms-key"
#   target_key_id = aws_kms_key.til_viewer_app_kms_key.id
# }

####################################
# Static Hosting
####################################
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
}

resource "aws_kms_alias" "til_viewer_app_kms_key" {
  name          = "alias/til-viewer-app-kms-key"
  target_key_id = aws_kms_key.til_viewer_app_kms_key.key_id
}

####################################
# Static Hosting Artifact
####################################
# data "aws_iam_policy_document" "til_viewer_app_artifact" {
#   version = "2012-10-17"
#   # デフォルトキーポリシー
#   statement {
#     sid = "Enable IAM User Permissions"
#     effect = "Allow"
#     principals {
#       type = "AWS"
#       identifiers = [ "arn:aws:iam::${data.aws_caller_identity.self.account_id}:root" ]
#     }
#     actions = [ "kms:*" ]
#     resources = [ "*" ]
#   }
# }

# resource "aws_kms_key" "static_hosting_artifact" {
#   description             = "static hosting customer managed key"
#   policy = data.aws_iam_policy_document.til_viewer_app_artifact.json
#   enable_key_rotation = true
#   # 検証用のため7日に設定
#   deletion_window_in_days = 7
# }

# resource "aws_kms_alias" "static_hosting_artifact" {
#   name          = "alias/${var.prefix}-static-hosting-artifact"
#   target_key_id = aws_kms_key.static_hosting_artifact.key_id
# }
