resource "aws_ecs_task_definition" "tbs-cache" {
  family                   = "${local.name_prefix}-cache"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-cache"
    image  = "${var.cache-image}:latest"
    memory = 512
    cpu    = 256
    essential = true
    environment = [
#
      ]
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/aws/ecs/${local.name_prefix}-cache-logs"
        awslogs-region        = "eu-west-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-middle-tier" })
}

resource "aws_ecs_service" "cache_tier" {
  name            = "${local.name_prefix}-cache-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-cache.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.frontend_sg.id, aws_security_group.cache_sg.id]
    assign_public_ip = false
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cache-service" })
}
