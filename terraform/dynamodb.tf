resource "aws_dynamodb_table" "items" {
  name         = "${terraform.workspace}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}
