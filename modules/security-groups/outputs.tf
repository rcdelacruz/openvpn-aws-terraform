output "openvpn_sg_id" {
  description = "ID of the OpenVPN security group"
  value       = aws_security_group.openvpn.id
}

output "openvpn_sg_arn" {
  description = "ARN of the OpenVPN security group"
  value       = aws_security_group.openvpn.arn
}

output "admin_sg_id" {
  description = "ID of the admin security group"
  value       = aws_security_group.admin.id
}

output "admin_sg_arn" {
  description = "ARN of the admin security group"
  value       = aws_security_group.admin.arn
}

output "load_balancer_sg_id" {
  description = "ID of the load balancer security group"
  value       = var.enable_load_balancer ? aws_security_group.load_balancer[0].id : null
}

output "load_balancer_sg_arn" {
  description = "ARN of the load balancer security group"
  value       = var.enable_load_balancer ? aws_security_group.load_balancer[0].arn : null
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = var.enable_database_sg ? aws_security_group.database[0].id : null
}

output "database_sg_arn" {
  description = "ARN of the database security group"
  value       = var.enable_database_sg ? aws_security_group.database[0].arn : null
}

output "all_security_group_ids" {
  description = "List of all security group IDs"
  value = compact([
    aws_security_group.openvpn.id,
    aws_security_group.admin.id,
    var.enable_load_balancer ? aws_security_group.load_balancer[0].id : null,
    var.enable_database_sg ? aws_security_group.database[0].id : null
  ])
}