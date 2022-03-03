resource "aws_route53_record" "bad_key" {
  depends_on = [module.child_zone]
  zone_id = module.parent_zone.zone_id
  name    = local.bad_key_domain
  type    = "DS"
  ttl     = "60"
  allow_overwrite = true
  records = [
      "12345 13 2 B8574CB22E4D99B1BBB1E76E47E7CABB664E58D344C40F02EC59E293845779EC"
      ]
}