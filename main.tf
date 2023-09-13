################################################################################
# Endpoint(s)
################################################################################

locals {
  endpoints = { for k, v in var.endpoints : k => v if var.create && try(v.create, true) }
}

data "aws_vpc_endpoint_service" "this" {
  for_each = local.endpoints

  service      = lookup(each.value, "service", null)
  service_name = lookup(each.value, "service_name", null)

  filter {
    name   = "service-type"
    values = [lookup(each.value, "service_type", "Interface")]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id            = var.vpc_id
  service_name      = data.aws_vpc_endpoint_service.this[each.key].service_name
  vpc_endpoint_type = lookup(each.value, "service_type", "Interface")
  auto_accept       = lookup(each.value, "auto_accept", null)

  security_group_ids  = lookup(each.value, "service_type", "Interface") == "Interface" ? length(distinct(concat(var.security_group_ids, lookup(each.value, "security_group_ids", [])))) > 0 ? distinct(concat(var.security_group_ids, lookup(each.value, "security_group_ids", []))) : null : null
  subnet_ids          = lookup(each.value, "service_type", "Interface") == "Interface" ? distinct(concat(var.subnet_ids, lookup(each.value, "subnet_ids", []))) : null
  route_table_ids     = lookup(each.value, "service_type", "Interface") == "Gateway" ? lookup(each.value, "route_table_ids", null) : null
  policy              = lookup(each.value, "policy", null)
  private_dns_enabled = lookup(each.value, "service_type", "Interface") == "Interface" ? lookup(each.value, "private_dns_enabled", null) : null

  tags = merge(var.tags, lookup(each.value, "tags", {}))

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "10m")
    delete = lookup(var.timeouts, "delete", "10m")
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  count = var.create && var.create_security_group ? 1 : 0

  name        = var.security_group_name
  name_prefix = var.security_group_name_prefix
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    var.security_group_tags,
    { "Name" = try(coalesce(var.security_group_name, var.security_group_name_prefix), "") },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if var.create && var.create_security_group }

  # Required
  security_group_id = aws_security_group.this[0].id
  protocol          = try(each.value.protocol, "tcp")
  from_port         = try(each.value.from_port, 443)
  to_port           = try(each.value.to_port, 443)
  type              = try(each.value.type, "ingress")

  # Optional
  description              = try(each.value.description, null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  self                     = try(each.value.self, null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}
