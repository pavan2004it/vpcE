output "dns_entry" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value = [for k in aws_vpc_endpoint.this : k.dns_entry[0]["dns_name"]]
}

output "hosted_zone" {
  value = [for k in aws_vpc_endpoint.this : k.dns_entry[0]["hosted_zone_id"]]
}
