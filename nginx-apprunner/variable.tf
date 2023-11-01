variable "service_name" {
  description = "The name of the service "
  type        = string
  default     = "sample-app-runner"
}

variable "auto_scaling_configurations" {
  description = "Map of auto-scaling configuration definitions to create "
  type        = any
  default     = {}
}

variable "source_configuration" {
  description = "The source configuration for the service "
  type        = any
  default     = {}
}

variable "enable_observability_configuration" {
  description = "Determines whether an X-Ray Observability Configuration will be created and assigned to the service "
  type        = bool
  default     = false
}

variable "private_ecr_arn" {
  description = "The ARN of the private ECR repository that contains the service image to launch "
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "vpc id."
}

variable "vpc_subnet1" {
  description = "vpc subnet1."
}

variable "vpc_subnet2" {
  description = "vpc subnet2."
}

variable "vpc_subnet3" {
  description = "vpc subnet3."
}
