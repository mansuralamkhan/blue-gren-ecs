aws_region        = "us-east-1"
app_name          = "my-app"
vpc_id            = "vpc-12345678"
subnets           = ["subnet-12345678", "subnet-87654321"]
blue_image        = "my-app:1.0.0"
green_image       = "my-app:2.0.0"
tfstate_bucket    = "my-tfstate-bucket"