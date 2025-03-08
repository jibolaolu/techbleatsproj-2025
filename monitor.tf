resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cluster" })
}

############################################

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.tbs_ecs_execution_role.arn
  #task_role_arn            = aws_iam_role.grafana_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "${var.prometheus-image}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "REDIS_URL", value = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379" },
        #         { name = "HTTP_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
        #         { name = "HTTPS_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
        #         { name = "HTTP_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}:3128" },
        #         { name = "HTTPS_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}:3128" },
        #         { name = "NO_PROXY", value = "169.254.169.254,localhost,.amazonaws.com" }
      ]
      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.name_prefix}-prometheus-logs"
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.prometheus.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.tbs_ecs_execution_role.arn
  #task_role_arn            = aws_iam_role.grafana_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "grafana"
      #image     = "grafana/grafana:latest"
      image     = "${var.grafana_image}:latest"
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "GF_SERVER_ROOT_URL", value = "http://${var.subdomain}.${var.domain_name}/grafana" },
        { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" } # ✅ Ensure Grafana serves from /grafana path
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.name_prefix}-grafana-logs"
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.grafana_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/aws/ecs/${local.name_prefix}-backend-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/aws/ecs/${local.name_prefix}-frontend-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cache_logs" {
  name              = "/aws/ecs/${local.name_prefix}-cache-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "garfana_logs" {
  name              = "/aws/ecs/${local.name_prefix}-grafana-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "prometheus_logs" {
  name              = "/aws/ecs/${local.name_prefix}-prometheus-logs"
  retention_in_days = 7
}