# OpenVPN Access Server on AWS with Terraform

A comprehensive, dynamic, and configurable Terraform setup for deploying OpenVPN Access Server on AWS EC2. This solution is designed for enterprise environments with support for large teams, high availability, monitoring, and automated backups.

## 🚀 Features

- **Dynamic Configuration**: Highly configurable with extensive variables
- **Modular Architecture**: Clean, maintainable Terraform modules
- **High Availability**: Optional Auto Scaling Group support
- **Security Best Practices**: Proper security groups, encrypted storage, SSM parameters
- **SSL Certificates**: Automatic Let's Encrypt certificate provisioning
- **Monitoring**: CloudWatch alarms and SNS notifications
- **Automated Backups**: S3-based backup solution with lifecycle policies
- **DNS Integration**: Route53 support for custom domains
- **Multi-Environment**: Support for dev, staging, and production environments

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Domain name (optional, for SSL certificates)
- Route53 hosted zone (optional, for DNS)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     AWS Account                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                    VPC                          │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │              Public Subnet              │   │   │
│  │  │                                         │   │   │
│  │  │  ┌─────────────────────────────────┐   │   │   │
│  │  │  │      OpenVPN Access Server     │   │   │   │
│  │  │  │                                 │   │   │   │
│  │  │  │  - Admin Web UI (943)          │   │   │   │
│  │  │  │  - Client Web UI (945)         │   │   │   │
│  │  │  │  - OpenVPN TCP (443)           │   │   │   │
│  │  │  │  - OpenVPN UDP (1194)          │   │   │   │
│  │  │  └─────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────┐ ┌─────────────────┐               │
│  │   CloudWatch    │ │      Route53    │               │
│  │   Monitoring    │ │   DNS Records   │               │
│  └─────────────────┘ └─────────────────┘               │
│                                                         │
│  ┌─────────────────┐ ┌─────────────────┐               │
│  │   S3 Backups    │ │   SNS Alerts    │               │
│  │   & Lifecycle   │ │   & Notifications│               │
│  └─────────────────┘ └─────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/rcdelacruz/openvpn-aws-terraform.git
cd openvpn-aws-terraform
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific configuration
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your OpenVPN Server

After deployment, Terraform will output important information:

```bash
# Get admin password
aws ssm get-parameter --name '/openvpn/openvpn/admin_password' --with-decryption --query 'Parameter.Value' --output text

# Access admin interface
# https://your-server-ip:943/admin

# Access client interface
# https://your-server-ip:945/
```

## ⚙️ Configuration Options

### Basic Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS deployment region |
| `environment` | `prod` | Environment name (dev/staging/prod) |
| `instance_type` | `t3.medium` | EC2 instance type |
| `name_prefix` | `openvpn` | Prefix for all resources |

### Network Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `create_vpc` | `true` | Create new VPC or use existing |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `allowed_cidr_blocks` | `["0.0.0.0/0"]` | Allowed client CIDR blocks |
| `admin_cidr_blocks` | `["0.0.0.0/0"]` | Allowed admin interface CIDR blocks |

### OpenVPN Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `admin_user` | `admin` | Admin username |
| `tcp_port` | `443` | TCP port for OpenVPN |
| `udp_port` | `1194` | UDP port for OpenVPN |
| `admin_port` | `943` | Admin web interface port |
| `reroute_gw` | `true` | Route client traffic through VPN |
| `reroute_dns` | `true` | Route DNS traffic through VPN |

### High Availability

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_high_availability` | `false` | Enable Auto Scaling Group |
| `min_size` | `1` | Minimum instances |
| `max_size` | `3` | Maximum instances |
| `desired_capacity` | `1` | Desired instances |

### SSL & DNS

| Variable | Default | Description |
|----------|---------|-------------|
| `domain_name` | `""` | Domain name for SSL certificate |
| `enable_ssl_cert` | `false` | Enable Let's Encrypt certificate |
| `create_dns_record` | `false` | Create Route53 DNS record |
| `hosted_zone_id` | `""` | Route53 hosted zone ID |

### Monitoring & Alerts

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_monitoring` | `true` | Enable CloudWatch monitoring |
| `cpu_alarm_threshold` | `80` | CPU alarm threshold (%) |
| `memory_alarm_threshold` | `80` | Memory alarm threshold (%) |
| `alert_email` | `""` | Email for alerts |

## 📁 Module Structure

```
.
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf             # Output definitions
├── versions.tf            # Provider versions
├── terraform.tfvars.example
├── modules/
│   ├── vpc/               # VPC module
│   ├── security-groups/   # Security groups module
│   ├── key-pair/          # Key pair module
│   ├── openvpn-server/    # OpenVPN server module
│   ├── monitoring/        # CloudWatch monitoring module
│   ├── dns/               # Route53 DNS module
│   └── backup/            # S3 backup module
├── environments/
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
└── scripts/
    ├── setup.sh          # Initial setup script
    ├── backup.sh         # Backup script
    └── user-management.sh # User management utilities
```

## 🔧 Advanced Usage

### Using Existing VPC

```hcl
create_vpc      = false
existing_vpc_id = "vpc-12345678"
```

### High Availability Setup

```hcl
enable_high_availability = true
min_size                = 1
max_size                = 3
desired_capacity        = 2
```

### Custom Domain with SSL

```hcl
domain_name       = "vpn.yourdomain.com"
enable_ssl_cert   = true
certificate_email = "admin@yourdomain.com"
create_dns_record = true
hosted_zone_id    = "Z1234567890ABC"
```

### Remote State Backend

Uncomment the backend configuration in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "openvpn/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

## 👥 User Management

### Web Interface

1. Access admin interface: `https://your-server:943/admin`
2. Login with admin credentials
3. Navigate to "User Management" → "User Permissions"
4. Add users as needed

### Command Line (SSH)

```bash
# SSH to instance
ssh -i your-key.pem openvpnas@your-server-ip

# Add user
sudo /usr/local/openvpn_as/scripts/sacli --user "newuser" --key "type" --value "user_connect" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user "newuser" --new_pass "password" SetLocalPassword

# List users
sudo /usr/local/openvpn_as/scripts/sacli UserPropGet

# Generate auto-login profile
sudo /usr/local/openvpn_as/scripts/sacli --user "username" GetAutologin > username.ovpn
```

## 📊 Monitoring & Maintenance

### CloudWatch Metrics

- CPU Utilization
- Memory Utilization  
- Disk Usage
- Network I/O
- Active VPN Connections

### Logs

```bash
# OpenVPN Access Server logs
sudo tail -f /var/log/openvpnas.log

# System logs
sudo journalctl -u openvpnas -f
```

### Backup & Recovery

Automated backups are stored in S3 with configurable retention:

```bash
# Manual backup
sudo /usr/local/openvpn_as/scripts/sacli ConfigBackup

# Restore from backup
sudo /usr/local/openvpn_as/scripts/sacli ConfigRestore
```

## 💰 Cost Optimization

1. **Right-size instances**: Start with `t3.medium`, scale as needed
2. **Use Spot instances**: For non-critical environments
3. **Reserved instances**: For long-term deployments
4. **Monitor data transfer**: Outbound traffic costs can add up
5. **Lifecycle policies**: Automatic cleanup of old backups

## 🔒 Security Best Practices

1. **Restrict admin access**: Limit `admin_cidr_blocks` to your office IPs
2. **Use strong passwords**: Enable auto-generated passwords
3. **Enable MFA**: Configure in the admin web interface
4. **Regular updates**: Keep OpenVPN Access Server updated
5. **Monitor logs**: Set up log analysis and alerting
6. **Network segmentation**: Limit VPN client access to specific resources

## 🧪 Testing

### Basic Connectivity Test

```bash
# Test admin interface
curl -k https://your-server:943/admin

# Test client interface  
curl -k https://your-server:945/

# Test OpenVPN ports
nc -zv your-server 443
nc -zuv your-server 1194
```

### Load Testing

For load testing with multiple concurrent connections, consider using:

- OpenVPN client automation scripts
- AWS Load Testing solutions
- Third-party VPN testing tools

## 🐛 Troubleshooting

### Common Issues

**Connection refused on admin port**
```bash
# Check if service is running
sudo systemctl status openvpnas

# Check firewall
sudo ufw status

# Check security groups in AWS console
```

**SSL certificate issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate
sudo certbot renew
```

**High CPU/Memory usage**
```bash
# Check active connections
sudo /usr/local/openvpn_as/scripts/sacli VPNStatus

# Monitor resources
htop
iostat 1
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- Create an issue for bug reports or feature requests
- Check the [OpenVPN Access Server documentation](https://openvpn.net/access-server/docs/)
- Review AWS documentation for service-specific issues

## 🎯 Roadmap

- [ ] Add support for OpenVPN Community Edition
- [ ] Integration with AWS Systems Manager Session Manager
- [ ] Automated user provisioning from LDAP/Active Directory
- [ ] Multi-region deployment support
- [ ] Terraform Cloud/Enterprise integration
- [ ] Advanced monitoring with custom metrics
- [ ] Cost optimization recommendations

---

**Made with ❤️ by [Ronald DC](https://github.com/rcdelacruz)**