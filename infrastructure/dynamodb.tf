resource "aws_dynamodb_table" "this" {
  name         = "DuaRequesterTable"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  global_secondary_index {
    name               = "UnreadDuaIndex"
    hash_key           = "UnreadDuaIndexPK"
    range_key          = "SK"
    projection_type    = "INCLUDE"
    non_key_attributes = ["Dua", "Posted"]
  }

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "UnreadDuaIndexPK"
    type = "S"
  }

  # attribute {
  #   name = "Dua"
  #   type = "S"
  # }
  #
  # attribute {
  #   name = "Posted"
  #   type = "S"
  # }
  #
  # attribute {
  #   name = "IsRead"
  #   type = "S"
  # }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}
