## ALB
resource "aws_lb" "this" {
  load_balancer_type = "application"
  name               = "redmine"

  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = [for v in aws_subnet.this : v.id if v.tags.Role == "public"]
}

## ALB Listener
## http
resource "aws_lb_listener" "this" {
  port     = "80"
  protocol = "HTTP"

  load_balancer_arn = aws_lb.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

# resource "aws_lb_listener" "this" {
#   port     = "80"
#   protocol = "HTTP"

#   load_balancer_arn = aws_lb.this.arn

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# ## https
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.this.arn

#   certificate_arn = aws_acm_certificate.tokyo["test-dom-info"].arn
#   port            = "443"
#   protocol        = "HTTPS"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.this.id
#   }
# }

# ELB Target Group
resource "aws_lb_target_group" "this" {
  name = "redmine"

  vpc_id = aws_vpc.this.id

  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 3000
    path = "/"
  }
}

# ELB Listener Rule
resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_lb_listener.this.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

