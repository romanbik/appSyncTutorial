variable "region" {
  description = "us-west-2"
}

variable "subnet_1_cidr" {
  default     = "172.31.48.0/20"
  description = "Your AZ"
}

variable "project" {
  default = "appsync-tutorial"
}

variable "prefix" {
  default = "development"
}



