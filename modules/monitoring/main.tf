# Monitoring Module for OpenVPN Setup
# Creates CloudWatch alarms and SNS notifications

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0
  
  name         = var.sns_topic_name
  display_name = "OpenVPN Alerts"
  
  tags = merge(
    var.tags,
    {
      Name = var.sns_topic_name
      Type = "sns_topic"
      Purpose = "monitoring"
    }
  )
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  count = var.create_sns_topic && var.alert_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarms for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = length(var.instance_ids)
  
  alarm_name          = "${var.name_prefix}-openvpn-high-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-high-cpu-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "cpu"
    }
  )
}

# CloudWatch Alarms for Memory Utilization (requires CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_memory_monitoring ? length(var.instance_ids) : 0
  
  alarm_name          = "${var.name_prefix}-openvpn-high-memory-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "OpenVPN/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "This metric monitors ec2 memory utilization"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-high-memory-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "memory"
    }
  )
}

# CloudWatch Alarms for Disk Utilization
resource "aws_cloudwatch_metric_alarm" "high_disk" {
  count = var.enable_disk_monitoring ? length(var.instance_ids) : 0
  
  alarm_name          = "${var.name_prefix}-openvpn-high-disk-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "used_percent"
  namespace           = "OpenVPN/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "This metric monitors ec2 disk utilization"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
    device     = "/dev/xvda1"
    fstype     = "ext4"
    path       = "/"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-high-disk-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "disk"
    }
  )
}

# CloudWatch Alarms for Network Utilization
resource "aws_cloudwatch_metric_alarm" "high_network_out" {
  count = length(var.instance_ids)
  
  alarm_name          = "${var.name_prefix}-openvpn-high-network-out-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.network_threshold
  alarm_description   = "This metric monitors ec2 network out utilization"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-high-network-out-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "network"
    }
  )
}

# CloudWatch Alarms for Instance Status Check
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  count = length(var.instance_ids)
  
  alarm_name          = "${var.name_prefix}-openvpn-instance-status-check-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors ec2 instance status check"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-instance-status-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "status_check"
    }
  )
}

# CloudWatch Alarms for System Status Check
resource "aws_cloudwatch_metric_alarm" "system_status_check" {
  count = length(var.instance_ids)
  
  alarm_name          = "${var.name_prefix}-openvpn-system-status-check-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors ec2 system status check"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions          = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-system-status-alarm-${count.index + 1}"
      Type = "cloudwatch_alarm"
      Metric = "status_check"
    }
  )
}

# Custom CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "openvpn" {
  count = var.create_dashboard ? 1 : 0
  
  dashboard_name = "${var.name_prefix}-openvpn-dashboard"
  
  dashboard_body = jsonencode({
    widgets = concat(
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              for instance_id in var.instance_ids : [
                "AWS/EC2", "CPUUtilization", "InstanceId", instance_id
              ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            period  = 300
            title   = "EC2 Instance CPU Utilization"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              for instance_id in var.instance_ids : [
                "AWS/EC2", "NetworkIn", "InstanceId", instance_id
              ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            period  = 300
            title   = "Network In"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              for instance_id in var.instance_ids : [
                "AWS/EC2", "NetworkOut", "InstanceId", instance_id
              ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            period  = 300
            title   = "Network Out"
          }
        }
      ],
      var.enable_memory_monitoring ? [
        {
          type   = "metric"
          x      = 12
          y      = 6
          width  = 12
          height = 6
          
          properties = {
            metrics = [
              for instance_id in var.instance_ids : [
                "OpenVPN/Server", "mem_used_percent", "InstanceId", instance_id
              ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            period  = 300
            title   = "Memory Utilization"
          }
        }
      ] : []
    )
  })
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-openvpn-dashboard"
      Type = "cloudwatch_dashboard"
    }
  )
}

# CloudWatch Log Insights Queries (for reference)
locals {
  log_insight_queries = {
    "OpenVPN Connection Events" = "fields @timestamp, @message | filter @message like /CONNECTED/ or @message like /DISCONNECTED/ | sort @timestamp desc"
    "OpenVPN Error Events"      = "fields @timestamp, @message | filter @message like /ERROR/ or @message like /WARN/ | sort @timestamp desc"
    "User Authentication"       = "fields @timestamp, @message | filter @message like /AUTH/ | sort @timestamp desc"
    "Certificate Events"        = "fields @timestamp, @message | filter @message like /CERT/ | sort @timestamp desc"
  }
}