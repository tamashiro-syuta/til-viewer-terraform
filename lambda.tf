resource "aws_lambda_function" "adding_commits_lambda" {
  filename      = "./lambda.zip"
  function_name = "AddingCommitsLambda"
  role          = aws_iam_role.adding_commits_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  environment {
    variables = {
      DYNAMODB_TABLE = "file-commits-table"
    }
  }
}
