terraform {
  backend "s3" {
    bucket         = "nginx-webcontent"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}