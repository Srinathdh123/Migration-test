variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "num_count" {
  default = 3
}

variable "ami" {
  default = "ami-094bbd9e922dc515d"
}

variable "s3_bucket" {
  default = "nginx-webcontent"
}