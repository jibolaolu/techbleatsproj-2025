resource "aws_security_group" "frontend_sg" {
  name        = "${local.name_prefix}-frontend-sg"
  description = "Security group for ECS tasks allowing traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB SG"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB SG"
  }

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
    description     = "Allow traffic from ALB SG"
  }

  egress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow outbound traffic to Middle Tier SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-frontend-sg" })
}

##################################################
##### BACK-END SECURITY GROUP
resource "aws_security_group" "backend_sg" {
  name   = "${local.name_prefix}-backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
    description     = "Allow traffic from ALB SG"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-backend-sg" })
}

resource "aws_security_group_rule" "backend_ingress_frontend" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  security_group_id = aws_security_group.backend_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow frontend traffic"
}

resource "aws_security_group_rule" "allow_alb_health_check" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id  # ✅ Allow ALB traffic
  description              = "Allow ALB health checks"
}



resource "aws_security_group_rule" "backend_egress_prometheus" {
  type              = "egress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  security_group_id = aws_security_group.backend_sg.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow Prometheus monitoring"
}

####################################################################################

##################CACHE SG START ##################
resource "aws_security_group" "cache_sg" {
  name   = "${local.name_prefix}-cache-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
    description     = "Allow traffic from ALB SG"
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cache-sg" })
}

resource "aws_security_group_rule" "cache_ingress_backend" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  security_group_id = aws_security_group.cache_sg.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow backend access to cache"
}

resource "aws_security_group_rule" "cache_egress_vpcendpoint" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cache_sg.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow ECS tasks to access AWS VPC Endpoints (ECR, S3) via PrivateLink"
}

resource "aws_security_group_rule" "cache_egress_squid" {
  type              = "egress"
  from_port         = 3128
  to_port           = 3128
  protocol          = "tcp"
  security_group_id = aws_security_group.cache_sg.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow backend access to cache"
}
######################## CACHE SG END###########################

# Create a Security Group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for Redis allowing access only from ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Allow ECS tasks to access Redis
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id, aws_security_group.cache_sg.id] # Allow ECS tasks to access Redis
    description     = "Allow Redis access from ECS tasks"
  }

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
    description     = "Allow traffic from ALB SG"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis-sg" })
}

#########################################

resource "aws_security_group" "prometheus" {
  name   = "${local.name_prefix}-prometheus-sg"
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-prometheus-sg" })
}
resource "aws_security_group_rule" "ecs_ingress_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  security_group_id = aws_security_group.prometheus.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow backend access to cache"
}

resource "aws_security_group_rule" "prometheus_egress_vpcendpoint" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.prometheus.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow backend access to cache"
}

##############################

resource "aws_security_group" "grafana_sg" {
  name   = "${local.name_prefix}-grafana-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-grafana-sg" })
}

resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-ALB-SG" })
}
