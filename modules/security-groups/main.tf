# Security Groups Module for OpenVPN Setup
# Creates security groups for OpenVPN Access Server

# OpenVPN Security Group
resource "aws_security_group" "openvpn" {
  name_prefix = "${var.name_prefix}-openvpn-"
  description = "Security group for OpenVPN Access Server"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # OpenVPN TCP Port
  dynamic "ingress" {
    for_each = var.enable_tcp_port ? [1] : []
    content {
      description = "OpenVPN TCP"
      from_port   = var.tcp_port
      to_port     = var.tcp_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # OpenVPN UDP Port
  dynamic "ingress" {
    for_each = var.enable_udp_port ? [1] : []
    content {
      description = "OpenVPN UDP"
      from_port   = var.udp_port
      to_port     = var.udp_port
      protocol    = "udp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Client Web Interface
  ingress {
    description = "Client Web Interface"
    from_port   = var.client_web_port
    to_port     = var.client_web_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-openvpn-sg"
      Type = "security_group"
      Purpose = "openvpn"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Admin Security Group (Separate for better security)
resource "aws_security_group" "admin" {
  name_prefix = "${var.name_prefix}-admin-"
  description = "Security group for OpenVPN Admin access"
  vpc_id      = var.vpc_id

  # Admin Web Interface
  ingress {
    description = "Admin Web Interface"
    from_port   = var.admin_port
    to_port     = var.admin_port
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # HTTPS for Let's Encrypt (if using SSL certificates)
  ingress {
    description = "HTTPS for SSL certificates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-admin-sg"
      Type = "security_group"
      Purpose = "admin"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Load Balancer Security Group (for High Availability setup)
resource "aws_security_group" "load_balancer" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = "${var.name_prefix}-lb-"
  description = "Security group for OpenVPN Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Admin Web Interface
  ingress {
    description = "Admin Web Interface"
    from_port   = var.admin_port
    to_port     = var.admin_port
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # Client Web Interface
  ingress {
    description = "Client Web Interface"
    from_port   = var.client_web_port
    to_port     = var.client_web_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-lb-sg"
      Type = "security_group"
      Purpose = "load_balancer"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group (for future use with RDS if needed)
resource "aws_security_group" "database" {
  count = var.enable_database_sg ? 1 : 0

  name_prefix = "${var.name_prefix}-db-"
  description = "Security group for OpenVPN Database"
  vpc_id      = var.vpc_id

  # MySQL/Aurora
  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.openvpn.id]
  }

  # PostgreSQL
  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.openvpn.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-sg"
      Type = "security_group"
      Purpose = "database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules for internal communication (if multiple instances)
resource "aws_security_group_rule" "openvpn_internal" {
  count = var.enable_internal_communication ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.openvpn.id
  security_group_id        = aws_security_group.openvpn.id
  description              = "Allow internal communication between OpenVPN instances"
}

# Custom security group rules (if needed)
resource "aws_security_group_rule" "custom_ingress" {
  count = length(var.custom_ingress_rules)

  type              = "ingress"
  from_port         = var.custom_ingress_rules[count.index].from_port
  to_port           = var.custom_ingress_rules[count.index].to_port
  protocol          = var.custom_ingress_rules[count.index].protocol
  cidr_blocks       = lookup(var.custom_ingress_rules[count.index], "cidr_blocks", null)
  security_group_id = aws_security_group.openvpn.id
  description       = lookup(var.custom_ingress_rules[count.index], "description", "Custom ingress rule")
}

resource "aws_security_group_rule" "custom_egress" {
  count = length(var.custom_egress_rules)

  type              = "egress"
  from_port         = var.custom_egress_rules[count.index].from_port
  to_port           = var.custom_egress_rules[count.index].to_port
  protocol          = var.custom_egress_rules[count.index].protocol
  cidr_blocks       = lookup(var.custom_egress_rules[count.index], "cidr_blocks", null)
  security_group_id = aws_security_group.openvpn.id
  description       = lookup(var.custom_egress_rules[count.index], "description", "Custom egress rule")
}