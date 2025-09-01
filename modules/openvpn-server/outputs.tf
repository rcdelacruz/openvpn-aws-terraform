output "instance_ids" {
  description = "List of OpenVPN instance IDs"
  value = var.enable_high_availability ? [] : aws_instance.openvpn[*].id
}

output "autoscaling_group_id" {
  description = "Auto Scaling Group ID (if high availability is enabled)"
  value = var.enable_high_availability ? aws_autoscaling_group.openvpn[0].id : null
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN (if high availability is enabled)"
  value = var.enable_high_availability ? aws_autoscaling_group.openvpn[0].arn : null
}

output "launch_template_id" {
  description = "Launch template ID"
  value = aws_launch_template.openvpn.id
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value = aws_launch_template.openvpn.latest_version
}

output "public_ips" {
  description = "List of public IP addresses"
  value = var.enable_high_availability ? [] : aws_instance.openvpn[*].public_ip
}

output "private_ips" {
  description = "List of private IP addresses"
  value = var.enable_high_availability ? [] : aws_instance.openvpn[*].private_ip
}

output "public_dns" {
  description = "List of public DNS names"
  value = var.enable_high_availability ? [] : aws_instance.openvpn[*].public_dns
}

output "private_dns" {
  description = "List of private DNS names"
  value = var.enable_high_availability ? [] : aws_instance.openvpn[*].private_dns
}

output "elastic_ips" {
  description = "List of Elastic IP addresses"
  value = var.enable_high_availability ? [] : aws_eip.openvpn[*].public_ip
}

output "elastic_ip_ids" {
  description = "List of Elastic IP allocation IDs"
  value = var.enable_high_availability ? [] : aws_eip.openvpn[*].id
}

# IAM Resources
output "iam_role_arn" {
  description = "ARN of IAM role for OpenVPN instances"
  value = aws_iam_role.openvpn_role.arn
}

output "iam_role_name" {
  description = "Name of IAM role for OpenVPN instances"
  value = aws_iam_role.openvpn_role.name
}

output "iam_instance_profile_arn" {
  description = "ARN of IAM instance profile"
  value = aws_iam_instance_profile.openvpn_profile.arn
}

output "iam_instance_profile_name" {
  description = "Name of IAM instance profile"
  value = aws_iam_instance_profile.openvpn_profile.name
}

# SSM Parameters
output "admin_password_ssm_parameter" {
  description = "SSM parameter name containing admin password"
  value = aws_ssm_parameter.admin_password.name
}

# CloudWatch
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value = aws_cloudwatch_log_group.openvpn.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value = aws_cloudwatch_log_group.openvpn.arn
}

# Network Information
output "subnet_ids_used" {
  description = "Subnet IDs used by instances"
  value = var.subnet_ids
}

output "security_group_ids_used" {
  description = "Security group IDs used by instances"
  value = var.security_group_ids
}

# Configuration Information
output "admin_user" {
  description = "Admin username"
  value = var.admin_user
}

output "tcp_port" {
  description = "TCP port used for OpenVPN"
  value = var.tcp_port
}

output "udp_port" {
  description = "UDP port used for OpenVPN"
  value = var.udp_port
}

output "vpn_network" {
  description = "VPN network for client IPs"
  value = "${var.vpn_network}/${var.vpn_netmask}"
}

output "domain_name" {
  description = "Domain name configured (if any)"
  value = var.domain_name
}

output "ssl_enabled" {
  description = "Whether SSL certificate is enabled"
  value = var.enable_ssl_cert
}

# URLs for easy access
output "admin_urls" {
  description = "Admin interface URLs"
  value = var.enable_high_availability ? [] : [
    for ip in (var.assign_elastic_ip ? aws_eip.openvpn[*].public_ip : aws_instance.openvpn[*].public_ip) :
    "https://${ip}:943/admin"
  ]
}

output "client_urls" {
  description = "Client interface URLs"
  value = var.enable_high_availability ? [] : [
    for ip in (var.assign_elastic_ip ? aws_eip.openvpn[*].public_ip : aws_instance.openvpn[*].public_ip) :
    "https://${ip}:945/"
  ]
}

output "domain_admin_url" {
  description = "Domain-based admin URL (if domain configured)"
  value = var.domain_name != "" ? "https://${var.domain_name}:943/admin" : null
}

output "domain_client_url" {
  description = "Domain-based client URL (if domain configured)"
  value = var.domain_name != "" ? "https://${var.domain_name}:945/" : null
}