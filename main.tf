provider "aws" {
  region = var.aws_region
}

# Local variable to determine the next environment
locals {
  current_environment = data.terraform_remote_state.current.outputs.active_environment
  next_environment    = var.target_environment != "" ? var.target_environment : (local.current_environment == "blue" ? "green" : "blue")
}


locals {
  current_environment = data.terraform_remote_state.current.outputs.active_environment
  next_environment = var.target_environment != "" ? var.target_environment: (local.current_environment == "blue" ? "green" : "blue")
}
# Data source to read the current state
data "terraform_remote_state" "current" {
  backend = "s3"
  config = {
    bucket = var.tfstate_bucket
    key    = "blue-green/terraform.tfstate"
    region = var.aws_region
  }
}

module "ecs" {
  source       = "./modules/ecs"
  app_name     = var.app_name
  aws_region   = var.aws_region
  vpc_id       = var.vpc_id
  subnets      = var.subnets
  blue_image   = var.blue_image
  green_image  = var.green_image
  environment  = local.next_environment
}

# Output the active environment
output "active_environment" {
  value = local.next_environment
}