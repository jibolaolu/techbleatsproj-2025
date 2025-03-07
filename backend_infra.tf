terraform {
  backend "s3" {
    bucket = "seunadio-tfstate"
    key    = "techbleats/infra.tfstate"
    region = "eu-west-2"
    encrypt = true
    dynamodb_table = var.dynano_table
  }
}