resource "aws_dynamodb_table" "file-commits-table" {
  name         = "file-commits-table"
  billing_mode = "PAY_PER_REQUEST" # NOTE: ほとんどアクセスがないので従量課金にする
  hash_key     = "date"
  range_key    = "path"

  attribute {
    name = "date"
    type = "N"
  }

  attribute {
    name = "path"
    type = "S"
  }

  tags = {
    Name = local.github_repository
  }
}
