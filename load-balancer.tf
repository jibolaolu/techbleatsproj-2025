resource "aws_lb" "tcs-alb" {
  name               = "${var.service}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-load-balancer" })
}

resource "aws_lb_target_group" "frontend_tg" {
  target_type = "ip"
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-frontend-target-group" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.tcs-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-target-group"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#Route "/api/*" to backend target group
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.tcs-alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.grafana_listener.arn
  priority     = 200

  condition {
    host_header {
      values = ["grafana.example.com"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}




