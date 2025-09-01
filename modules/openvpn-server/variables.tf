variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for OpenVPN Access Server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "admin_user" {
  description = "Admin username for OpenVPN Access Server"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password for OpenVPN Access Server"
  type        = string
  default     = ""
  sensitive   = true
}

variable "reroute_gw" {
  description = "Should client traffic be routed through VPN"
  type        = bool
  default     = true
}

variable "reroute_dns" {
  description = "Should client DNS traffic be routed through VPN"
  type        = bool
  default     = true
}

variable "vpn_network" {
  description = "VPN network for client IP allocation"
  type        = string
  default     = "172.27.224.0"
}

variable "vpn_netmask" {
  description = "VPN netmask bits for client IP pool"
  type        = number
  default     = 20
}

variable "tcp_port" {
  description = "TCP port for OpenVPN"
  type        = number
  default     = 443
}

variable "udp_port" {
  description = "UDP port for OpenVPN"
  type        = number
  default     = 1194
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = ""
}

variable "enable_ssl_cert" {
  description = "Enable automatic SSL certificate with Let's Encrypt"
  type        = bool
  default     = false
}

variable "certificate_email" {
  description = "Email for Let's Encrypt certificate"
  type        = string
  default     = ""
}

# High Availability Configuration
variable "enable_high_availability" {
  description = "Enable high availability with Auto Scaling Group"
  type        = bool
  default     = false
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "target_group_arns" {
  description = "List of target group ARNs for load balancer"
  type        = list(string)
  default     = []
}

# Storage Configuration
variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# Network Configuration
variable "assign_elastic_ip" {
  description = "Assign Elastic IP to single instance"
  type        = bool
  default     = true
}

# Security Configuration
variable "kms_key_id" {
  description = "KMS key ID for encrypting SSM parameters"
  type        = string
  default     = "alias/aws/ssm"
}

variable "hosted_zone_arn" {
  description = "Route53 hosted zone ARN for DNS permissions"
  type        = string
  default     = ""
}

variable "backup_bucket_arn" {
  description = "S3 bucket ARN for backup permissions"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}