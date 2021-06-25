
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
    default = "eu-west-1"
}

variable "network_address_space" {
    default = "10.0.0.0/16"
}

variable "subnet1_address_space" {
    default = "10.0.100.0/24"
}

variable "subnet2_address_space" {
    default = "10.0.200.0/24"
}

variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
variable "environment_tag" {}
