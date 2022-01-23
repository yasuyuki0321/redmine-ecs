# ACM
locals {
  domains = {
    test-dom-info = {
      domain_name               = "test-dom.info"
      subject_alternative_names = [] # 空の場合 *.domain_name を自動で追加 個別にサブドメインを指定したい場合に指定
      cloudfront                = true
      zone_id                   = aws_route53_zone.public["test-dom-info"].zone_id
    }
  }
}

## Create ACM
resource "aws_acm_certificate" "tokyo" {
  for_each = local.domains

  domain_name               = each.value.domain_name
  subject_alternative_names = length(each.value.subject_alternative_names) == 0 ? ["*.${each.value.domain_name}"] : each.value.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

## Create ACM for CoudFront
resource "aws_acm_certificate" "virginia" {
  for_each = { for k, v in local.domains : k => v if v.cloudfront == true }

  provider                  = aws.virginia
  domain_name               = each.value.domain_name
  subject_alternative_names = length(each.value.subject_alternative_names) == 0 ? ["*.${each.value.domain_name}"] : each.value.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

## Register varidation code
resource "aws_route53_record" "acm-varidation-code" {
  for_each = local.domains

  name    = one(toset(aws_acm_certificate.tokyo[each.key].domain_validation_options[*].resource_record_name))
  records = toset(aws_acm_certificate.tokyo[each.key].domain_validation_options[*].resource_record_value)
  ttl     = 60
  type    = one(toset(aws_acm_certificate.tokyo[each.key].domain_validation_options[*].resource_record_type))
  zone_id = each.value.zone_id
}
