variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_ids" {
  description = "List of instance IDs to monitor"
  type        = list(string)
}

variable "create_sns_topic" {
  description = "Create SNS topic for alerts"
  type        = bool
  default     = true
}

variable "sns_topic_name" {
  description = "Name of SNS topic for alerts"
  type        = string
  default     = "openvpn-alerts"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "disk_threshold" {
  description = "Disk utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "network_threshold" {
  description = "Network utilization threshold for alarm (bytes)"
  type        = number
  default     = 1000000000  # 1GB
}

variable "enable_memory_monitoring" {
  description = "Enable memory utilization monitoring (requires CloudWatch Agent)"
  type        = bool
  default     = true
}

variable "enable_disk_monitoring" {
  description = "Enable disk utilization monitoring (requires CloudWatch Agent)"
  type        = bool
  default     = true
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}