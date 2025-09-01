variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to OpenVPN"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access admin interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_tcp_port" {
  description = "Enable TCP port for OpenVPN"
  type        = bool
  default     = true
}

variable "enable_udp_port" {
  description = "Enable UDP port for OpenVPN"
  type        = bool
  default     = true
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

variable "admin_port" {
  description = "Port for admin web interface"
  type        = number
  default     = 943
}

variable "client_web_port" {
  description = "Port for client web interface"
  type        = number
  default     = 945
}

variable "enable_load_balancer" {
  description = "Enable load balancer security group"
  type        = bool
  default     = false
}

variable "enable_database_sg" {
  description = "Enable database security group"
  type        = bool
  default     = false
}

variable "enable_internal_communication" {
  description = "Enable internal communication between OpenVPN instances"
  type        = bool
  default     = false
}

variable "custom_ingress_rules" {
  description = "List of custom ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    description = optional(string)
  }))
  default = []
}

variable "custom_egress_rules" {
  description = "List of custom egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    description = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}