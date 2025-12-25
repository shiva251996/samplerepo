variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "subs" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}
