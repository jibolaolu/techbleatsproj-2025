resource "aws_iam_role" "tbs_ecs_execution_role" {
  name = "${local.name_prefix}-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-exec-role" })
}

resource "aws_iam_policy" "tbs_ecs_exec_policy" {
  name        = "${local.name_prefix}-ecsExecPolicy"
  description = "Policy for ECS Exec command and logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }


    ]
  })
}

resource "aws_iam_role_policy_attachment" "tbs_ecs_task_execution_role_policy" {
  role       = aws_iam_role.tbs_ecs_execution_role.name
  policy_arn = aws_iam_policy.tbs_ecs_exec_policy.arn
}

resource "aws_iam_role" "grafana_ecs_role" {
  name = "${local.name_prefix}-promgrafa-tsk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-promgrafa-tsk-role" })
}

resource "aws_iam_policy" "grafana_ecs_policy" {
  name        = "${local.name_prefix}-ecs-grafana-role-policy"
  description = "Policy for ECS task role to allow Prometheus & Grafana to access AWS services"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tbs_ecs_role_attachment" {
  role       = aws_iam_role.grafana_ecs_role.name
  policy_arn = aws_iam_policy.grafana_ecs_policy.arn
}

###### ECS TASK EXECUTION ROLE ######

resource "aws_iam_role" "tbs_task_execution_role" {
  name = "ecs-task-role-techbleats"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "tbs_task_execution_policy" {
  name        = "ecs-task-policy-redis"
  description = "IAM policy for ECS task role to write into Redis cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource"
        ]
        Resource = "arn:aws:elasticache:eu-west-2:100753669199:cluster/my-redis-cluster"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role       = aws_iam_role.tbs_task_execution_role.name
  policy_arn = aws_iam_policy.tbs_task_execution_policy.arn
}
