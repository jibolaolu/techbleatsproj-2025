resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cluster" })
}

resource "aws_ecs_task_definition" "tbs-frontend" {
  family                   = "${local.name_prefix}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = "512"
  memory                   = "1024"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-front-end"
    image  = "${var.front-end-image}:latest"
    memory = 1024
    cpu    = 512
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/aws/ecs/${local.name_prefix}-frontend-logs"
        awslogs-region        = "eu-west-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-frontend" })
}

resource "aws_ecs_service" "frontend" {
  name            = "${local.name_prefix}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "${local.name_prefix}-front-end"
    container_port   = 80
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-front-service" })
}

#############################################

resource "aws_ecs_task_definition" "tbs-middle" {
  family                   = "${local.name_prefix}-middle-tier"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-middle-tier"
    image  = "${var.cache-image}:latest"
    memory = 512
    cpu    = 256
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/aws/ecs/${local.name_prefix}-middle-tier-logs"
        awslogs-region        = "eu-west-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-middle-tier" })
}

resource "aws_ecs_service" "middle_tier" {
  name            = "${local.name_prefix}-middle-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-middle.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.frontend_sg.id, aws_security_group.cache_sg.id]
    assign_public_ip = false
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-middle-service" })
}

############################################

resource "aws_ecs_task_definition" "tbs-backend" {
  family                   = "${local.name_prefix}backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = "${local.name_prefix}-backend"
      image     = "${var.back-end-image}:latest"
      memory    = 512
      cpu       = 256
      essential = true
      environment = [
        { name = "REDIS_URL", value = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379" },
        { name = "HTTP_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
        { name = "HTTPS_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
        { name = "NO_PROXY", value = "169.254.169.254,localhost,.amazonaws.com" }
      ]
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.name_prefix}-backend-logs"
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${local.name_prefix}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.backend_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "${local.name_prefix}-backend"
    container_port   = 8000
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-backend-sevice" })
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      cpu       = 256
      memory    = 512
      essential = true
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

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
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

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.grafana.id]
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

resource "aws_cloudwatch_log_group" "middle_tier_logs" {
  name              = "/aws/ecs/${local.name_prefix}-middle-tier-logs"
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