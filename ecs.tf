resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cluster" })
}

resource "aws_ecs_task_definition" "tbs-frontend" {
  family                   = "${local.name_prefix}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-front-end"
    image  = "${var.front-end-image}:latest"
    memory = 512
    cpu    = 256
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-frontend" })
}

resource "aws_ecs_task_definition" "tbs-middle" {
  family                   = "${local.name_prefix}-middle-tier"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-springboot-def"
    image  = "${var.cache-image}:latest"
    memory = 512
    cpu    = 256
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-middle-tier" })
}

resource "aws_ecs_task_definition" "tbs-backend" {
  family                   = "${local.name_prefix}-redis-cache"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.tbs_ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name   = "${local.name_prefix}-redis-def"
    image  = "${var.back-end-image}:latest"
    memory = 512
    cpu    = 256
    portMappings = [{
      containerPort = 6379
      hostPort      = 6379
    }]
  }])
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis" })
}

resource "aws_ecs_service" "frontend" {
  name            = "${local.name_prefix}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "${local.name_prefix}-front-end"
    container_port   = 80
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-front-service" })
}

resource "aws_ecs_service" "middle_tier" {
  name            = "${local.name_prefix}-middle-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-middle.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-middle-service" })
}

resource "aws_ecs_service" "redis-cache" {
  name            = "${local.name_prefix}-redis-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tbs-backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis-sevice" })
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks allowing traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-ecs-security-group" })
}
