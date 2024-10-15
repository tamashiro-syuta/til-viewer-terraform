# ------------------------------------------------------------
# NOTE: TILのGitHubActionsでS3に画像ファイルをアップロードするユーザー
# ------------------------------------------------------------

# NOTE: IAMユーザーの作成
# NOTE: "upload_til_image_user"はterraform内で参照するためのエイリアス
resource "aws_iam_user" "upload_til_image_user" {
  name = "upload_til_image_user"
}

# NOTE: S3へのアップロード用ポリシーの作成
resource "aws_iam_policy" "s3_operate_policy" {
  name        = "TILImageBucketUploadPolicy"
  description = "Allows to upload objects to the TIL Viewer Images bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.til_viewer_images.arn}",
          "${aws_s3_bucket.til_viewer_images.arn}/*"
        ]
      }
    ]
  })
}

# NOTE: IAMユーザーにポリシーをアタッチ
resource "aws_iam_user_policy_attachment" "upload_til_image_user_policy" {
  user       = aws_iam_user.upload_til_image_user.name
  policy_arn = aws_iam_policy.s3_operate_policy.arn
}

# NOTE: アクセスキーの作成
resource "aws_iam_access_key" "upload_til_image_user_access_key" {
  user = aws_iam_user.upload_til_image_user.name
}

# NOTE: 出力でアクセスキーを表示
output "upload_til_image_user_access_key_id" {
  value = aws_iam_access_key.upload_til_image_user_access_key.id
}

output "upload_til_image_user_secret_access_key" {
  value     = aws_iam_access_key.upload_til_image_user_access_key.secret
  sensitive = true
}

# ------------------------------------------------------------
# NOTE: TIL-Viewerで利用するユーザー
# ------------------------------------------------------------
resource "aws_iam_user" "til_viewer_app_user" {
  name = "til_viewer_app_user"
}

resource "aws_iam_policy" "dynamodb_read_policy" {
  name        = "TILViewerDynamoDBReadPolicy"
  description = "Allows to read objects from the TIL Viewer DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.file-commits-table.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "s3_fetch_policy" {
  name        = "TILImageBucketFetchPolicy"
  description = "Allows to get objects to the TIL Viewer Images bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.til_viewer_images.arn}",
          "${aws_s3_bucket.til_viewer_images.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "til_viewer_app_user_dynamodb_read_policy" {
  user       = aws_iam_user.til_viewer_app_user.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_iam_user_policy_attachment" "til_viewer_app_user_s3_fetch_policy" {
  user       = aws_iam_user.til_viewer_app_user.name
  policy_arn = aws_iam_policy.s3_fetch_policy.arn
}

resource "aws_iam_access_key" "til_viewer_app_user_access_key" {
  user = aws_iam_user.til_viewer_app_user.name
}
output "til_viewer_app_user_access_key_id" {
  value = aws_iam_access_key.til_viewer_app_user_access_key.id
}

output "til_viewer_app_user_secret_access_key" {
  value     = aws_iam_access_key.til_viewer_app_user_access_key.secret
  sensitive = true
}

# ------------------------------------------------------------
# NOTE: TIL-Viewerでdynamoにデータを書き込むためのユーザー
# ------------------------------------------------------------
resource "aws_iam_user" "til_viewer_dynamodb_write_user" {
  name = "til_viewer_dynamodb_write_user"
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name        = "TILViewerDynamoDBWritePolicy"
  description = "Allows to write objects to the TIL Viewer DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.file-commits-table.arn
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "til_viewer_dynamodb_write_user_policy" {
  user       = aws_iam_user.til_viewer_dynamodb_write_user.name
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

resource "aws_iam_access_key" "til_viewer_dynamodb_write_user_access_key" {
  user = aws_iam_user.til_viewer_dynamodb_write_user.name
}

output "til_viewer_dynamodb_write_access_key_id" {
  value = aws_iam_access_key.til_viewer_dynamodb_write_user_access_key.id
}

output "til_viewer_dynamodb_write_secret_access_key" {
  value     = aws_iam_access_key.til_viewer_dynamodb_write_user_access_key.secret
  sensitive = true
}

# ------------------------------------------------------------
# NOTE: TIL-ViewerをデプロイするためのID Provider と IAM ROLE
# ------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "deploy_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = var.client_id_list
  thumbprint_list = var.thumbprint_list
}

resource "aws_iam_role" "deploy_actions_role" {
  name        = "deploy_actions_role"
  description = "Allows to deploy TIL Viewer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.deploy_actions.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" : "repo:tamashiro-syuta/til-viewer:*",
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "til_viewer_deploy_policy" {
  name = "TILViewerDeployPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.til_viewer_app.arn}",
          "${aws_s3_bucket.til_viewer_app.arn}/*"
        ]
      },
      {
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:ListStreamingDistributions",
          "cloudfront:CreateInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetInvalidation",
        ],
        Effect = "Allow",
        Resource = [
          aws_cloudfront_distribution.til_viewer_app.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "til_viewer_deploy_policy_attachment" {
  role       = aws_iam_role.deploy_actions_role.name
  policy_arn = aws_iam_policy.til_viewer_deploy_policy.arn
}
