variable "domain_name" {}
variable "bucket_name" {}
variable "certificate_transparency_logging_preference" {
  type = bool
  default = true
}
variable "child_domains"{
    type = list(string)
    default = []
}


module "acm_request_certificate" {
  source = "cloudposse/acm-request-certificate/aws"

  domain_name                       = var.domain_name
  subject_alternative_names         = ["*.${var.domain_name}"]
  process_domain_validation_options = true
  ttl                               = "300"
  certificate_transparency_logging_preference = var.certificate_transparency_logging_preference
}

# Parent CDN
module "cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.82.3"

  name      = "dnssec"
  stage     = "demo"
  namespace = var.domain_name


  origin_bucket                     = var.bucket_name
  default_root_object               = "index.html"
  min_ttl                           = 1
  default_ttl                       = 3
  max_ttl                           = 5
  cloudfront_access_logging_enabled = false
  dns_alias_enabled                 = false # don't set DNS, we'll set them in child zones accordingly
  aliases                           = setunion([var.domain_name], var.child_domains)
  parent_zone_name                  = var.domain_name
  acm_certificate_arn               = module.acm_request_certificate.arn
  depends_on                        = [module.acm_request_certificate]
}

output "cf_domain_name" {
  value =  module.cdn.cf_domain_name
}

output "cf_hosted_zone_id" {
  value =  module.cdn.cf_hosted_zone_id
}