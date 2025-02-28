# resource "aws_security_group" "vpc_endpoint_sg" {
#   name        = "${local.name_prefix}-vpc-endpoint-sg"
#   description = "Security group for AWS PrivateLink VPC Endpoints"
#   vpc_id      = aws_vpc.main.id
#
#   # ✅ Allow inbound traffic from ECS backend tasks (HTTPS for AWS API)
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     security_groups = [aws_security_group.backend_sg.id, aws_security_group.prometheus.id, aws_security_group.cache_sg.id]  # ✅ Allow only backend tasks
#     description = "Allow ECS backend to access AWS ECR via VPC Endpoints"
#   }
#
#   # ✅ Allow outbound traffic to AWS ECR, S3, and AWS services
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow VPC endpoints to communicate with AWS services"
#   }
#
#   tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc-endpoint-sg" })
# }
#
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.private[*].id
#   security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
#   private_dns_enabled = true
#
#   tags =  merge(local.common_tags, { Name = "${local.name_prefix}-ecr-endpoint" })
# }
#
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = aws_subnet.private[*].id
#   security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
#   private_dns_enabled = true
#   tags =  merge(local.common_tags, { Name = "${local.name_prefix}-ecr_dkr-endpoint" })
#
# }
#
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.tbs-private-rt.id]
# }
#
# resource "aws_vpc_endpoint" "cloudwatch_logs" {
#   vpc_id             = aws_vpc.main.id
#   service_name       = "com.amazonaws.eu-west-2.logs"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = aws_subnet.private[*].id
#   security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
#   private_dns_enabled = true
# }
#
