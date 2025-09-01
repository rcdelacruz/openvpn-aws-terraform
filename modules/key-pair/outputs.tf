output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.main.key_name
}

output "key_pair_id" {
  description = "Key pair ID"
  value       = aws_key_pair.main.key_pair_id
}

output "key_fingerprint" {
  description = "SHA256 fingerprint of the key pair"
  value       = aws_key_pair.main.fingerprint
}

output "private_key_ssm_parameter" {
  description = "SSM parameter name containing the private key"
  value       = aws_ssm_parameter.private_key.name
}

output "public_key_ssm_parameter" {
  description = "SSM parameter name containing the public key"
  value       = aws_ssm_parameter.public_key.name
}

output "key_fingerprint_ssm_parameter" {
  description = "SSM parameter name containing the key fingerprint"
  value       = aws_ssm_parameter.key_fingerprint.name
}

output "ssh_connection_command" {
  description = "Command to retrieve private key and connect via SSH"
  value       = "aws ssm get-parameter --name '${aws_ssm_parameter.private_key.name}' --with-decryption --query 'Parameter.Value' --output text > /tmp/openvpn-key.pem && chmod 600 /tmp/openvpn-key.pem"
}

# Don't output the actual private key for security
# output "private_key_pem" {
#   description = "Private key in PEM format"
#   value       = tls_private_key.main.private_key_pem
#   sensitive   = true
# }

output "public_key_openssh" {
  description = "Public key in OpenSSH format"
  value       = tls_private_key.main.public_key_openssh
}