#!/bin/bash
# OpenVPN Access Server User Data Script
# Configures OpenVPN Access Server on first boot

set -e

# Variables from Terraform
ADMIN_USER="${admin_user}"
ADMIN_PASSWORD="${admin_password}"
REROUTE_GW="${reroute_gw}"
REROUTE_DNS="${reroute_dns}"
VPN_NETWORK="${vpn_network}"
VPN_NETMASK="${vpn_netmask}"
TCP_PORT="${tcp_port}"
UDP_PORT="${udp_port}"
DOMAIN_NAME="${domain_name}"
ENABLE_SSL_CERT="${enable_ssl_cert}"
CERTIFICATE_EMAIL="${certificate_email}"
NAME_PREFIX="${name_prefix}"
AWS_REGION="${aws_region}"

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting OpenVPN Access Server configuration..."
date

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
    awscli \
    jq \
    curl \
    wget \
    unzip \
    certbot \
    amazon-cloudwatch-agent

# Configure CloudWatch Agent
echo "Configuring CloudWatch Agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/openvpnas.log",
            "log_group_name": "/aws/ec2/openvpn/${name_prefix}",
            "log_stream_name": "{instance_id}/openvpnas.log"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/openvpn/${name_prefix}",
            "log_stream_name": "{instance_id}/user-data.log"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "OpenVPN/Server",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Wait for OpenVPN Access Server to be ready
echo "Waiting for OpenVPN Access Server to initialize..."
sleep 60

# Check if OpenVPN Access Server is installed
if [ ! -f "/usr/local/openvpn_as/scripts/sacli" ]; then
    echo "ERROR: OpenVPN Access Server not found!"
    exit 1
fi

# Configure OpenVPN Access Server
echo "Configuring OpenVPN Access Server..."

# Stop OpenVPN temporarily for configuration
/usr/local/openvpn_as/scripts/sacli stop

# Basic configuration
/usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "local" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.0" --value "${vpn_network}/${vpn_netmask}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.subnet" --value "${vpn_network}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.netmask_bits" --value "${vpn_netmask}" ConfigPut

# Configure ports
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.daemon.tcp.port" --value "${tcp_port}" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.daemon.udp.port" --value "${udp_port}" ConfigPut

# Configure routing
if [ "${reroute_gw}" = "true" ]; then
    /usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.gateway_access" --value "true" ConfigPut
    /usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_gw" --value "true" ConfigPut
fi

if [ "${reroute_dns}" = "true" ]; then
    /usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_dns" --value "true" ConfigPut
    /usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.dns.0" --value "8.8.8.8" ConfigPut
    /usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.dns.1" --value "8.8.4.4" ConfigPut
fi

# Optimize for large teams
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.daemon.tcp.n_daemons" --value "4" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.daemon.udp.n_daemons" --value "4" ConfigPut

# Configure admin user
echo "Creating admin user..."
/usr/local/openvpn_as/scripts/sacli --user "${admin_user}" --key "type" --value "user_connect" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "${admin_user}" --key "prop_superuser" --value "true" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "${admin_user}" --key "prop_admin" --value "true" UserPropPut
/usr/local/openvpn_as/scripts/sacli --user "${admin_user}" --new_pass "${admin_password}" SetLocalPassword

# Configure SSL certificate if domain is provided
if [ -n "${domain_name}" ] && [ "${enable_ssl_cert}" = "true" ] && [ -n "${certificate_email}" ]; then
    echo "Configuring SSL certificate for domain: ${domain_name}"
    
    # Get certificate from Let's Encrypt
    certbot certonly --standalone --non-interactive --agree-tos --email "${certificate_email}" -d "${domain_name}"
    
    if [ $? -eq 0 ]; then
        echo "SSL certificate obtained successfully"
        
        # Configure OpenVPN to use the certificate
        /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/${domain_name}/cert.pem" ConfigPut
        /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/${domain_name}/privkey.pem" ConfigPut
        /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file "/etc/letsencrypt/live/${domain_name}/chain.pem" ConfigPut
        
        # Set up automatic renewal
        echo "0 12 * * * /usr/bin/certbot renew --quiet && /usr/local/openvpn_as/scripts/sacli restart" | crontab -
    else
        echo "Failed to obtain SSL certificate"
    fi
fi

# Start OpenVPN Access Server
echo "Starting OpenVPN Access Server..."
/usr/local/openvpn_as/scripts/sacli start

# Wait for services to start
sleep 30

# Enable IP forwarding
echo "Configuring IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Configure firewall if ufw is enabled
if command -v ufw >/dev/null 2>&1; then
    echo "Configuring firewall..."
    ufw --force enable
    ufw allow ssh
    ufw allow ${tcp_port}/tcp
    ufw allow ${udp_port}/udp
    ufw allow 943/tcp
    ufw allow 945/tcp
    ufw allow 80/tcp  # For Let's Encrypt
fi

# Store configuration status in SSM Parameter
aws ssm put-parameter \
    --name "/${name_prefix}/openvpn/config_status" \
    --value "completed" \
    --type "String" \
    --overwrite \
    --region "${aws_region}"

# Store instance information
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

aws ssm put-parameter \
    --name "/${name_prefix}/openvpn/instance_info" \
    --value "{\"instance_id\":\"${INSTANCE_ID}\",\"public_ip\":\"${PUBLIC_IP}\",\"private_ip\":\"${PRIVATE_IP}\"}" \
    --type "String" \
    --overwrite \
    --region "${aws_region}"

echo "OpenVPN Access Server configuration completed!"
echo "Admin URL: https://${PUBLIC_IP}:943/admin"
echo "Client URL: https://${PUBLIC_IP}:945/"
echo "Admin User: ${admin_user}"
echo "Configuration completed at: $(date)"

# Send success notification (optional)
# aws sns publish --topic-arn "arn:aws:sns:${aws_region}:$(aws sts get-caller-identity --query Account --output text):${name_prefix}-openvpn-notifications" --message "OpenVPN Access Server configuration completed successfully for instance ${INSTANCE_ID}" --region "${aws_region}" || true

exit 0