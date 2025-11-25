variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "db_password_user" {
  description = "User DB password"
  type        = string
  sensitive   = true
}

variable "db_password_analysis" {
  description = "Analysis DB password"
  type        = string
  sensitive   = true
}

variable "db_password_location" {
  description = "Location DB password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "pass"
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "hK8nX2mP9qR5vT3wL7bE4jY6cA1dF8sZ"
}
