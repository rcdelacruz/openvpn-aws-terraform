variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_ids" {
  description = "List of OpenVPN instance IDs to backup"
  type        = list(string)
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting S3 objects"
  type        = string
  default     = "alias/aws/s3"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_backup_notifications" {
  description = "Enable S3 bucket notifications for backup completion"
  type        = bool
  default     = false
}

variable "backup_notification_lambda_arn" {
  description = "Lambda function ARN for backup notifications"
  type        = string
  default     = ""
}

variable "enable_ia_transition" {
  description = "Enable transition to Infrequent Access storage class"
  type        = bool
  default     = true
}

variable "ia_transition_days" {
  description = "Days after which to transition to IA storage class"
  type        = number
  default     = 30
}

variable "enable_glacier_transition" {
  description = "Enable transition to Glacier storage class"
  type        = bool
  default     = true
}

variable "glacier_transition_days" {
  description = "Days after which to transition to Glacier storage class"
  type        = number
  default     = 90
}

variable "enable_deep_archive_transition" {
  description = "Enable transition to Deep Archive storage class"
  type        = bool
  default     = false
}

variable "deep_archive_transition_days" {
  description = "Days after which to transition to Deep Archive storage class"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}