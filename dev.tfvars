vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
environment          = "development"
service              = "techbleats-stocks"
cache-image          = "100753669199.dkr.ecr.eu-west-2.amazonaws.com/teach-bleats-cache"
back-end-image       = "100753669199.dkr.ecr.eu-west-2.amazonaws.com/tech-bleats-backend"
front-end-image      = "100753669199.dkr.ecr.eu-west-2.amazonaws.com/tech-bleats-frontend"
