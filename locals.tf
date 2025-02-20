locals {
  common_tags = {
    Environment = var.environment
    Provisioner = "Terraform"
    Project     = "TechBleats Solutions"
    Service     = var.service
  }
  name_prefix = "${var.environment}-${var.service}"
}
