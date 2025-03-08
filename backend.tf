resource "aws_ecs_task_definition" "tbs-backend" {
  family                   = "${local.name_prefix}backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.tbs_ecs_task_execution_role.arn
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
#         { name = "HTTP_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
#         { name = "HTTPS_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}/squid-proxy" },
#         { name = "HTTP_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}:3128" },
#         { name = "HTTPS_PROXY", value = "http://${aws_lb.tcs-alb.dns_name}:3128" },
#         { name = "NO_PROXY", value = "169.254.169.254,localhost,.amazonaws.com" }
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