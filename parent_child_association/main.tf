resource "aws_route53_record" "NS" {
  zone_id = var.parent_zone_id
  name    = var.child_domain
  type    = "NS"
  ttl     = "60"
  records = var.child_name_servers
}

resource "aws_route53_record" "DS" {
  zone_id = var.parent_zone_id
  name    = var.child_domain
  type    = "DS"
  ttl     = "60"
  records = [var.child_ds_record]

  # we will update DS records later
  lifecycle {    
      ignore_changes = all
  }
}