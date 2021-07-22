# output "jumpbox_dns_name" {
#   description = "Jumpbox DNS name"
#   value       = aws_instance.jumpbox.public_dns
# }

# output "public_dns_names" {
#   description = "Public DNS names of the components"
#   value       = { for p in sort(keys(var.component)) : p => aws_instance.component[p].public_dns }
# }

output "public_dns_names" {
  description = "Public DNS names of the components"
  value       = { for p in sort(keys(local.service_instances_map)) : p => aws_instance.component[p].public_dns }
}

# output "web_public_address" {
#   value = "${aws_instance.web.public_ip}:8080"
# }

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = local.aws_vpc_id
}

output "aws_ipv4_cidr" {
  description = "AWS IPv4 CIDR"
  value       = local.aws_ipv4_cidr
}

output "aws_subnet_id" {
  description = "AWS Subnet ID"
  value       = local.aws_subnet_id
}
