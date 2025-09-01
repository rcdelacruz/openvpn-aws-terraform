variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "algorithm" {
  description = "Algorithm for key generation"
  type        = string
  default     = "RSA"

  validation {
    condition     = contains(["RSA", "ECDSA", "ED25519"], var.algorithm)
    error_message = "Algorithm must be one of: RSA, ECDSA, ED25519."
  }
}

variable "rsa_bits" {
  description = "Number of bits for RSA key"
  type        = number
  default     = 2048

  validation {
    condition     = contains([2048, 3072, 4096], var.rsa_bits)
    error_message = "RSA bits must be one of: 2048, 3072, 4096."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting SSM parameters"
  type        = string
  default     = "alias/aws/ssm"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}