terraform {
  backend "s3" {
    bucket = "seunadio-tfstate"
    key    = "techbleats/infra.tfstate"
    region = "eu-west-2"
  }
}