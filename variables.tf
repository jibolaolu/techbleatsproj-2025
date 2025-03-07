variable "aws_region" {
  default = "eu-west-2"
}

variable "environment" {
  default = ""
}

variable "service" {
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "route53_zone_id" {
  default = "Z093721723YGO5T9U48BI"
}

variable "instance_ami" {
  type    = string
  default = "ami-05bca204debf5aaeb"
}

variable "keypair" {
  type    = string
  default = "LinuxKeyPair"
}

variable "front-end-image" {}

variable "back-end-image" {}

variable "cache-image" {}
variable "domain_name" {}
variable "subdomain" {}

variable "squid-image" {}
variable "prometheus-image" {}
variable "grafana_image" {}
variable "dynamo_table" {
  type = string
  default = "terraform-states-table"
}
