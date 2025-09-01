output "backup_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = aws_s3_bucket.backup.bucket
}

output "backup_bucket_arn" {
  description = "ARN of the backup S3 bucket"
  value       = aws_s3_bucket.backup.arn
}

output "backup_bucket_id" {
  description = "ID of the backup S3 bucket"
  value       = aws_s3_bucket.backup.id
}

output "backup_lambda_function_name" {
  description = "Name of the backup Lambda function"
  value       = aws_lambda_function.backup.function_name
}

output "backup_lambda_function_arn" {
  description = "ARN of the backup Lambda function"
  value       = aws_lambda_function.backup.arn
}

output "backup_schedule_rule_name" {
  description = "Name of the CloudWatch Event Rule for backup schedule"
  value       = aws_cloudwatch_event_rule.backup_schedule.name
}

output "backup_schedule_rule_arn" {
  description = "ARN of the CloudWatch Event Rule for backup schedule"
  value       = aws_cloudwatch_event_rule.backup_schedule.arn
}

output "backup_lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.backup_lambda_role.arn
}

output "backup_lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.backup_lambda_role.name
}

output "backup_lambda_log_group_name" {
  description = "Name of the Lambda function's CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_lambda_logs.name
}

output "backup_lambda_log_group_arn" {
  description = "ARN of the Lambda function's CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_lambda_logs.arn
}

output "backup_schedule_expression" {
  description = "Cron expression for backup schedule"
  value       = var.backup_schedule
}

output "backup_retention_days" {
  description = "Number of days backups are retained"
  value       = var.backup_retention_days
}

output "backup_bucket_lifecycle_rule" {
  description = "S3 bucket lifecycle configuration details"
  value = {
    expiration_days = var.backup_retention_days
    ia_transition_enabled = var.enable_ia_transition
    ia_transition_days = var.ia_transition_days
    glacier_transition_enabled = var.enable_glacier_transition
    glacier_transition_days = var.glacier_transition_days
    deep_archive_transition_enabled = var.enable_deep_archive_transition
    deep_archive_transition_days = var.deep_archive_transition_days
  }
}

output "manual_backup_command" {
  description = "AWS CLI command to manually trigger a backup"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.backup.function_name} --payload '{}' /tmp/backup-response.json"
}

output "backup_restoration_instructions" {
  description = "Instructions for restoring from backup"
  value = {
    step1 = "Download backup from S3: aws s3 cp s3://${aws_s3_bucket.backup.bucket}/backups/BACKUP_FILE.tar.gz /tmp/"
    step2 = "Extract backup: tar -xzf /tmp/BACKUP_FILE.tar.gz -C /tmp/"
    step3 = "SSH to OpenVPN instance and restore configuration"
    step4 = "Stop OpenVPN: sudo /usr/local/openvpn_as/scripts/sacli stop"
    step5 = "Restore config: sudo /usr/local/openvpn_as/scripts/sacli ConfigRestore < /path/to/config_backup.json"
    step6 = "Start OpenVPN: sudo /usr/local/openvpn_as/scripts/sacli start"
  }
}