output "sns_topic_arn" {
  description = "ARN of SNS topic for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "sns_topic_name" {
  description = "Name of SNS topic for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].name : null
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value = var.create_dashboard ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.openvpn[0].dashboard_name}" : null
}

output "alarm_arns" {
  description = "List of CloudWatch alarm ARNs"
  value = concat(
    aws_cloudwatch_metric_alarm.high_cpu[*].arn,
    aws_cloudwatch_metric_alarm.high_memory[*].arn,
    aws_cloudwatch_metric_alarm.high_disk[*].arn,
    aws_cloudwatch_metric_alarm.high_network_out[*].arn,
    aws_cloudwatch_metric_alarm.instance_status_check[*].arn,
    aws_cloudwatch_metric_alarm.system_status_check[*].arn
  )
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = concat(
    aws_cloudwatch_metric_alarm.high_cpu[*].alarm_name,
    aws_cloudwatch_metric_alarm.high_memory[*].alarm_name,
    aws_cloudwatch_metric_alarm.high_disk[*].alarm_name,
    aws_cloudwatch_metric_alarm.high_network_out[*].alarm_name,
    aws_cloudwatch_metric_alarm.instance_status_check[*].alarm_name,
    aws_cloudwatch_metric_alarm.system_status_check[*].alarm_name
  )
}

output "log_insight_queries" {
  description = "Useful CloudWatch Log Insights queries"
  value       = local.log_insight_queries
}