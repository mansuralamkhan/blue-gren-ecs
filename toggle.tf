# Initialize the state with a default active environment if it doesn't exist
resource "aws_s3_bucket_object" "initial_state" {
  bucket  = var.tfstate_bucket
  key     = "blue-green/terraform.tfstate"
  content = jsonencode({
    outputs = {
      active_environment = "blue"
    }
  })
  count = fileexists("${path.module}/terraform.tfstate") ? 0 : 1
}                                    