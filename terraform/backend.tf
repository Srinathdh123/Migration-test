terraform {
  backend "s3" {
    bucket         = "nginx-webcontent"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}