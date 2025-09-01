# OpenVPN Server Module
# Creates EC2 instances with OpenVPN Access Server

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random password for admin user if not provided
resource "random_password" "admin_password" {
  count   = var.admin_password == "" ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Store admin password in SSM Parameter Store
resource "aws_ssm_parameter" "admin_password" {
  name        = "/${var.name_prefix}/openvpn/admin_password"
  description = "Admin password for OpenVPN Access Server"
  type        = "SecureString"
  value       = var.admin_password != "" ? var.admin_password : random_password.admin_password[0].result
  key_id      = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-admin-password"
      Type = "ssm_parameter"
      Purpose = "openvpn_admin"
    }
  )
}

# IAM Role for OpenVPN instances
resource "aws_iam_role" "openvpn_role" {
  name = "${var.name_prefix}-openvpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for OpenVPN instances
resource "aws_iam_role_policy" "openvpn_policy" {
  name = "${var.name_prefix}-openvpn-policy"
  role = aws_iam_role.openvpn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = var.hosted_zone_arn != "" ? [var.hosted_zone_arn] : ["*"]
        Condition = var.hosted_zone_arn != "" ? {} : {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = var.backup_bucket_arn != "" ? [
          "${var.backup_bucket_arn}/*"
        ] : []
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/openvpn*"
      }
    ]
  })
}

# Attach AWS Systems Manager policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.openvpn_role.name
}

# Attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.openvpn_role.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "openvpn_profile" {
  name = "${var.name_prefix}-openvpn-profile"
  role = aws_iam_role.openvpn_role.name

  tags = var.tags
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    admin_user      = var.admin_user
    admin_password  = var.admin_password != "" ? var.admin_password : random_password.admin_password[0].result
    reroute_gw      = var.reroute_gw
    reroute_dns     = var.reroute_dns
    vpn_network     = var.vpn_network
    vpn_netmask     = var.vpn_netmask
    tcp_port        = var.tcp_port
    udp_port        = var.udp_port
    domain_name     = var.domain_name
    enable_ssl_cert = var.enable_ssl_cert
    certificate_email = var.certificate_email
    name_prefix     = var.name_prefix
    aws_region      = data.aws_region.current.name
  }))
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "openvpn" {
  name_prefix   = "${var.name_prefix}-openvpn-"
  description   = "Launch template for OpenVPN Access Server"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.openvpn_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = var.root_volume_type
      volume_size           = var.root_volume_size
      delete_on_termination = true
      encrypted             = true
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-openvpn"
        Type = "openvpn_server"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-openvpn-volume"
        Type = "ebs_volume"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# Auto Scaling Group (High Availability)
resource "aws_autoscaling_group" "openvpn" {
  count = var.enable_high_availability ? 1 : 0

  name                = "${var.name_prefix}-openvpn-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.openvpn.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-openvpn-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Single EC2 Instance (when not using High Availability)
resource "aws_instance" "openvpn" {
  count = var.enable_high_availability ? 0 : 1

  launch_template {
    id      = aws_launch_template.openvpn.id
    version = "$Latest"
  }

  subnet_id = var.subnet_ids[0]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-openvpn"
      Type = "openvpn_server"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for single instance (optional)
resource "aws_eip" "openvpn" {
  count = var.enable_high_availability ? 0 : (var.assign_elastic_ip ? 1 : 0)

  instance = aws_instance.openvpn[0].id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-openvpn-eip"
      Type = "elastic_ip"
    }
  )

  depends_on = [aws_instance.openvpn]
}

# CloudWatch Log Group for OpenVPN logs
resource "aws_cloudwatch_log_group" "openvpn" {
  name              = "/aws/ec2/openvpn/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-openvpn-logs"
      Type = "cloudwatch_log_group"
    }
  )
}