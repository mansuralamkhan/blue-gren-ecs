aws_region = "us-east-1"
app_name = "my-app"
vpc_id = "vpc-1233"
subnets = ["subnet-123", "subnet-232"]
blue_image = "my-app:1.0.0"
green_image = "my-app:2.0.0"
tfstate_bucket = "my-tfstate-bucket"


variable "app_name" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "subnets" {type = list(string)}
variable "blue_image" {}
variable "green_image" {}
variable "environment" {}

data "aws_vpc" "selected" {
    id = var.vpc_id

}

resource "aws_security_group" "ecs_sg" {
    vpc_id = var.vpc_id
    name = "${var.app_name}-ecs-sg"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_lb" "app" {
    name = "${var.app}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.ecs_sg.id]
    subnets = var.subnets
}

resource "aws_lb_target_group" "blue" {
    name = "${var.app_name}-blue-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id
    target_type = "ip"

    health_check {
      path = "/"
      interval = 30
      timeout = 5
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}



resource "aws_lb_target_group" "green" {
    name = "${var.app_name}-green-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id
    target_type = "ip"

    health_check {
      path = "/"
      interval = 30
      timeout = 5
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}


resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.app.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = var.environment == "blue" ? aws_lb_target_group.blue : aws_lb_target_group.green.arn

    }



}


resource "aws_ecs-cluster" "app" {
    name = "${var.appname}-cluster"

}

resource "aws_ecs_task_definition" "blue" {
    family = "${var.app_name}-blue"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_task_execution_role.policy_arn

    container_definitions = jsoncode([{
        name = "${var.app_name}-blue"
        image = var.blue_image
        essential = true
        portMappings = [{
            container_port = 80
            hostPort = 80
        }]
    }])
}

resource "aws_ecs_task_definition" "green" {
    family = "${var.app_name}-green"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_task_execution_role.policy_arn

    container_definitions = jsoncode([{
        name = "${var.app_name}-green"
        image = var.green_image
        essential = true
        portMappings = [{
            container_port = 80
            hostPort = 80
        }]
    }])
}


resource "aws_ecs_service" "blue" {
    name = "${var.app_name}-blue-servive"
    cluster = aws_ecs_cluster.app.id
    task_definition = aws_ecs_task_definition.blue.arn
    desired_count = var.environment == "blue" ? 2: 0
    launch_type = "FARGATE"

    network_configuration {
      subnets = var.subnets
      security_groups = [aws_security_group.ecs_sg.id]
      assign_public_ip = true
    }

    load_balancer {
      target_group_arn = aws_lb_target_group.blue.arn
      container_name = "${var.app_name}-blue"
      container_port = 80
    }

    depends_on = [ aws_lb_listener.http ]
}


resource "aws_ecs_service" "green" {
  name            = "${var.app_name}-green-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.green.arn
  desired_count   = var.environment == "green" ? 2 : 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "${var.app_name}-green"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}


resource "aws_iam_role" "ecs_task_execution_role" {
    name = "${var.app_name}-ecs-task-execution-role"

    assume_role_policy = jsoncode({
        Verson = "2012-10-17"
        statement = [{
            Action = "sts:Assumerole"
            Effect = "Alow"
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
    role = aws_iam_role.ecs_task_execution_role
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}




variable "aws-region" {
    description = "AWS region"
    type = string
}

variable "app_name" {
    description = "Application name"
    type = string
}

variable "vpc_id" {
    description = "VPC ID"
    type = string
}

variable "subnets" {
    description = "List of subnet IDs"
    type = list(string)
}

variable "blue_image" {
    description = "Docker image for Blue environment"
    type = string

}

variable "green_image" {
    description = "Docker image for green environment"
    type = string
}

variable "target_environment" {
    description = "Target environment to dploy"
    type = string
    default = ""
}

variable "tfstate_bucket" {
    description = "S3 bucket for terraform state"
    type = string
}


resource "aws_s3_bucket_objet" "initial-state" {
    bucket = var.tfstate_bucket
    key = "blue-green/terraform.tfstate"
    contents = jsoncode({
        outputs = {
            active_environment = "blue"
        }
    })

    count = fileexists("${path.module}/terraform.tfstate") ? 0: 1
}

provider "aws" {
    region = var.aws_region
}

locals {
    current_environment = data.terraform_remote_state.current.outputs.active_environment
    next_environment = var.target_environment != "" ? var.target_environment : (local.current_environment == "blue" ? "green" : "blue")

}

data "terraform_remote_state" "current" {
    backend = "s3"
    config = {
        bucket = var.tfstate_bucket
        key = "blue-green/terraform.tfstate"
        region = var.aws-region
    }
}


module "ecs" {
    source = "./modules/ecs"
    app_name = var.app_name
    aws_region = var.aws_region
    vpc_ic = var.vpc_id
    subnets = var.subnets
    blue_image = var.blue_image
    green_image = var.green_image
    environment = local.next_environment
}