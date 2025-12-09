terraform {
  backend "s3" {
    role_arn = "arn:aws:iam::345848277895:role/venmo-central-terraform-backend-us-east-1-automation"
    bucket   = "venmo-central-terraform-backend-us-east-1-automation"
    dynamodb_table = "venmo-central-terraform-backend-us-east-1-automation"
    encrypt  = true
    key      = "venmo/k8s-image-swapper-webhook/k8s-image-swapper/terraform.tfstate"
    kms_key_id = "arn:aws:kms:us-east-1:345848277895:key/6d94sfe8-6f23-45a4-8a15-7b6aa9f52220"
    region   = "us-east-1"
    workspace_key_prefix = "env:"
  }
}
