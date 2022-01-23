## Security Group ELB
resource "aws_security_group" "alb" {
  name        = "${var.system_name}-alb-sg-01"
  description = "${var.system_name} security group for application load balancer"
  vpc_id      = aws_vpc.this.id

  # http
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    prefix_list_ids = [aws_ec2_managed_prefix_list.this["kikuchi"].id]
  }

  # https
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    prefix_list_ids = [aws_ec2_managed_prefix_list.this["kikuchi"].id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "${var.system_name}-alb-sg-01"
  }
}

# ## Security Groups ECS
resource "aws_security_group" "ecs" {
  name        = "${var.system_name}-ecs-sg-01"
  description = "${var.system_name} Security group for ecs"
  vpc_id      = aws_vpc.this.id

  # http
  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"

    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "${var.system_name}-ecs-sg-01"
  }
}

## Security Group RDS
resource "aws_security_group" "this" {
  name        = "${var.system_name}-rds-sg-01"
  description = "${var.system_name} security group for aurora serverless "
  vpc_id      = aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
