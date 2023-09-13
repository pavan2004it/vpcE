output "dns_entry" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value = [for k in aws_vpc_endpoint.this : k.dns_entry[0]["dns_name"]]
}

output "hosted_zone" {
  value = [for k in aws_vpc_endpoint.this : k.dns_entry[0]["hosted_zone_id"]]
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this[0].arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this[0].id, null)
}
