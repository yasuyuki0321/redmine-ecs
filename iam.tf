# ECS TaskExecutionRole
data "aws_iam_policy_document" "ecs-task-execution-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs-task-execution-role" {
  name               = "${var.system_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs-task-execution-role.json
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


#  ECS TaskRole
data "aws_iam_policy_document" "ecs-task-role" {
  version = "2012-10-17"
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs-task-role" {
  name_prefix = "${var.system_name}-ecs-task-role"
  policy = data.aws_iam_policy_document.ecs-task-role.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-role" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = aws_iam_policy.ecs-task-role.arn
}
