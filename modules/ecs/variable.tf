variable "app_name" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "subnets" { type = list(string) }
variable "blue_image" {}
variable "green_image" {}
variable "environment" {}