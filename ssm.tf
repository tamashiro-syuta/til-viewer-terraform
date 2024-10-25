resource "aws_secretsmanager_secret" "adding_commits_lambda_secret" {
  name        = "adding_commits_lambda_secret"
  description = "This secret stores the API key for the Lambda function"
}

resource "aws_secretsmanager_secret_version" "api_secret_version" {
  secret_id     = aws_secretsmanager_secret.adding_commits_lambda_secret.id
  secret_string = jsonencode({
    GITHUB_TOKEN = var.github_token
  })
}
