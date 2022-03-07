
# Single Bucket and Cert for all deployments
module "website_bucket" {
  source        = "./s3_bucket"
  bucket_prefix = "dnssec-demo-123"
}

module "acm_request_certificate" {
  source = "cloudposse/acm-request-certificate/aws"

  domain_name                       = local.parent_domain
  subject_alternative_names         = ["*.${local.parent_domain}"]
  process_domain_validation_options = true
  ttl                               = "300"
}

# Parent CDN
module "cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.82.3"

  name      = "dnssec"
  stage     = "demo"
  namespace = "parent"


  origin_bucket                     = module.website_bucket.bucket_name
  default_root_object               = "index.html"
  min_ttl                           = 1
  default_ttl                       = 3
  max_ttl                           = 5
  cloudfront_access_logging_enabled = false
  dns_alias_enabled                 = false # don't set DNS, we'll set them in child zones accordingly
  aliases                           = setunion([local.parent_domain], local.child_domains)
  parent_zone_name                  = local.parent_domain
  acm_certificate_arn               = module.acm_request_certificate.arn
  depends_on                        = [module.acm_request_certificate]
}

resource "aws_route53_record" "parent" {

  zone_id         = module.parent_zone.zone_id
  name            = local.parent_domain
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = module.cdn.cf_domain_name
    zone_id                = module.cdn.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "children" {
  for_each = module.child_zone
  
  zone_id         = each.value.zone_id
  name            = each.key
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = module.cdn.cf_domain_name
    zone_id                = module.cdn.cf_hosted_zone_id
    evaluate_target_health = false
  }
}