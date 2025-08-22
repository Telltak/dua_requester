resource "aws_dynamodb_table" "this" {
  name         = "${var.service_name}-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  global_secondary_index {
    name               = "UnreadDuaIndex"
    hash_key           = "UnreadDuaIndexPK"
    range_key          = "SK"
    projection_type    = "INCLUDE"
    non_key_attributes = ["Dua", "PostedBy"]
  }

  global_secondary_index {
    name            = "ClaimedDuaIndex"
    hash_key        = "ClaimedDuaIndexPK"
    range_key       = "ClaimedAt"
    projection_type = "KEYS_ONLY"
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

  attribute {
    name = "ClaimedDuaIndexPK"
    type = "S"
  }

  attribute {
    name = "ClaimedAt"
    type = "S"
  }

  # attribute {
  #   name = "Dua"
  #   type = "S"
  # }
  #
  # attribute {
  #   name = "PostedBy"
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
