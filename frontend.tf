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
