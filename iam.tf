# ------------------------------------------------------------
# NOTE: TILのGitHubActionsでS3に画像ファイルをアップロードするユーザー
# ------------------------------------------------------------

# NOTE: IAMユーザーの作成
# NOTE: "upload_til_image_user"はterraform内で参照するためのエイリアス
resource "aws_iam_user" "upload_til_image_user" {
  name = "tupload_til_image_user"
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
          "${aws_s3_bucket.til-viewer.arn}",
          "${aws_s3_bucket.til-viewer.arn}/*"
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
resource "aws_iam_access_key" "github_actions_access_key" {
  user = aws_iam_user.upload_til_image_user.name
}

# NOTE: 出力でアクセスキーを表示
output "github_actions_access_key_id" {
  value = aws_iam_access_key.github_actions_access_key.id
}

output "github_actions_secret_access_key" {
  value     = aws_iam_access_key.github_actions_access_key.secret
  sensitive = true
}

# ------------------------------------------------------------
# NOTE: TIL-Viewerでdynamoからデータをfetchするためのユーザー
# ------------------------------------------------------------
resource "aws_iam_user" "til_viewer_dynamodb_read_user" {
  name = "til_viewer_dynamodb_read_user"
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

resource "aws_iam_user_policy_attachment" "til_viewer_dynamodb_read_user_policy" {
  user       = aws_iam_user.til_viewer_dynamodb_read_user.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_iam_access_key" "til_viewer_dynamodb_read_user_access_key" {
  user = aws_iam_user.til_viewer_dynamodb_read_user.name
}
output "til_viewer_dynamodb_access_key_id" {
  value = aws_iam_access_key.til_viewer_dynamodb_read_user_access_key.id
}

output "til_viewer_dynamodb_secret_access_key" {
  value     = aws_iam_access_key.til_viewer_dynamodb_read_user_access_key.secret
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
  user = aws_iam_user.til_viewer_dynamodb_read_user.name
}

output "til_viewer_dynamodb_write_access_key_id" {
  value = aws_iam_access_key.til_viewer_dynamodb_write_user_access_key.id
}

output "til_viewer_dynamodb_write_secret_access_key" {
  value     = aws_iam_access_key.til_viewer_dynamodb_write_user_access_key.secret
  sensitive = true
}
