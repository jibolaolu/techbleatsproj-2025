resource "aws_ecs_task_definition" "squid" {
  family                   = "squid-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "squid"
      image     = "${var.squid-image}:latest"
      memory    = 512
      cpu       = 256
      essential = true
      portMappings = [
        {
          containerPort = 3128
          hostPort      = 3128
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.name_prefix}-squid-logs"
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "squid_service" {
  name            = "${local.name_prefix}-squid-proxy-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.squid.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.squid_sg.id]
    assign_public_ip = true
  }
}

resource "aws_cloudwatch_log_group" "squid_logs" {
  name              = "/aws/ecs/${local.name_prefix}-squid-logs"
  retention_in_days = 7
}

resource "aws_lb_target_group" "squid_tg" {
  name        = "squid-proxy-tg"
  port        = 3128
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-squid-logs" })
}

resource "aws_lb_listener_rule" "squid_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 150
  condition {
    path_pattern {
      values = ["/squid-proxy/*"] # ✅ Requests to this path go to Squid
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.squid_tg.arn
  }
}

resource "aws_security_group" "squid_sg" {
  name        = "${local.name_prefix}-squid-proxy-sg"
  description = "Security group for Squid Proxy"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3128
    to_port         = 3128
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id, aws_security_group.cache_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-squid-proxy-sg" })
}
