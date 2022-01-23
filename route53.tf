# Route53

locals {
  public_zones = {
    test-dom-info = {
      zone_name = "test-dom.info"
    }
  }
  private_zones = {
    local = {
      zone_name = "local"
      vpc_id    = aws_vpc.this.id
    }
  }
}

## Route53 Host Zone Name(public)
resource "aws_route53_zone" "public" {
  for_each = local.public_zones

  name    = each.value.zone_name
  comment = "-"
}

## Route53 Host Zone Name(private)
resource "aws_route53_zone" "private" {
  for_each = local.private_zones

  name    = each.value.zone_name
  comment = "-"

  vpc {
    vpc_id = each.value.vpc_id
  }
}
