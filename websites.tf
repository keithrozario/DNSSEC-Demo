
# Single Bucket and Cert for all deployments
module website_bucket {
  source = "./s3_bucket"
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
  source = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.82.3"

  name                          = "dnssec"
  stage                         = "demo"
  namespace                     = "parent"

  dns_alias_enabled = true
  origin_bucket     = module.website_bucket.bucket_name
  cloudfront_access_logging_enabled = false
  aliases           = [local.parent_domain]
  parent_zone_name  = local.parent_domain
  default_root_object = "index.html"
  min_ttl = 1
  default_ttl = 3
  max_ttl = 5

  acm_certificate_arn = module.acm_request_certificate.arn
  depends_on = [module.acm_request_certificate]
}

# Child Zone CDN
module "cdn_child" {
  for_each = module.child_zone

  source = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.82.3"

  name                          = "dnssec"
  stage                         = "demo"
  namespace                     = each.key

  dns_alias_enabled = true
  origin_bucket     = module.website_bucket.bucket_name
  cloudfront_access_logging_enabled = false
  aliases           = [each.key]
  parent_zone_name  = each.key
  default_root_object = "index.html"
  min_ttl = 1
  default_ttl = 3
  max_ttl = 5

  acm_certificate_arn = module.acm_request_certificate.arn
  depends_on = [module.acm_request_certificate]
}