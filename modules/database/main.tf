resource "aws_dynamodb_table" "tokens_table" {
  name         = "team-diamonds-tokens"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "integrationType"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "integrationType"
    type = "S"
  }
}