## ECS Log Group
resource "aws_cloudwatch_log_group" "redmine" {
  name              = "/ecs/redmine/app"
  retention_in_days = 3
}

## ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "redmine"
}

# ## Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "redmine"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = <<EOL
[
  {
    "name": "redmine",
    "image": "public.ecr.aws/docker/library/redmine:latest",
    "essential": true,
    "environment": [
      {
        "name": "REDMINE_DB_MYSQL",
        "value": "${aws_rds_cluster.this.endpoint}"
      },
      {
        "name": "REDMINE_DB_USERNAME",
        "value": "${var.db_user}"
      },
      {
        "name": "REDMINE_DB_PASSWORD",
        "value": "${var.db_password}"
      },
      {
         "name": "REDMINE_DB_DATABASE",
        "value": "${aws_rds_cluster.this.database_name}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-northeast-1",
        "awslogs-stream-prefix": "redmine",
        "awslogs-group": "/ecs/redmine/app"
      }
    }
  }
]
EOL
}

# ECS Service
resource "aws_ecs_service" "this" {
  name = "redmine"

  depends_on = [aws_lb_listener_rule.this]

  cluster       = aws_ecs_cluster.this.name
  launch_type   = "FARGATE"
  desired_count = 1
  enable_execute_command = true


  task_definition = aws_ecs_task_definition.this.arn

  network_configuration {
    subnets          = [for v in aws_subnet.this : v.id if v.tags.Role == "private"]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true # TODO NAT G/W設定したら不要
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "redmine"
    container_port   = "3000"
  }
}
