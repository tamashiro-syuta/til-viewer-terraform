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
        Effect   = "Allow"
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
  value = aws_iam_access_key.github_actions_access_key.secret
  sensitive = true
}
