resource "aws_route53_zone" "this" {
  name = var.domain
  force_destroy = true
}

resource "aws_route53_record" "dummy" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "60"
  records = ["127.0.0.1"]
}

## Turn on DNSSEC for Parent Zone
resource "aws_route53_key_signing_key" "this" {
  hosted_zone_id             = aws_route53_zone.this.id
  key_management_service_arn = var.ksk_key_arn
  name                       = "KSK"
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  depends_on = [
    aws_route53_key_signing_key.this
  ]
  hosted_zone_id = aws_route53_key_signing_key.this.hosted_zone_id
}