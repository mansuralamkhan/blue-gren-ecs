variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "blue_image" {
  description = "Docker image for Blue environment"
  type        = string
}

variable "green_image" {
  description = "Docker image for Green environment"
  type        = string
}

variable "target_environment" {
  description = "Target environment to deploy (blue or green). If empty, toggles automatically."
  type        = string
  default     = ""
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}