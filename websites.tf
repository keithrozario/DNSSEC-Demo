
# Single Bucket and Cert for all deployments
module "website_bucket_main" {
  source        = "./s3_bucket"
  bucket_prefix = "dnssec-demo-123"
}

# Single Bucket and Cert for all deployments
module "website_bucket_no_ct" {
  source        = "./s3_bucket"
  bucket_prefix = "dnssec-demo-123"
}

module "cf_website_main" {
# Creates one single CF distribution backed by an S3 bucket
# ACM Cert will be valid for *.domain_name (wildcard) -- not just the child domains
  source = "./cf_website"
  domain_name = local.parent_domain
  child_domains = [for domain in local.child_domains : domain if domain != local.no_cert_logging_domain]
  bucket_name = module.website_bucket_main.bucket_name
}

module "cf_website_no_ct_log" {
  source = "./cf_website"
  domain_name = local.no_cert_logging_domain
  bucket_name = module.website_bucket_no_ct.bucket_name
  certificate_transparency_logging_preference = false
}

resource "aws_route53_record" "parent" {

  zone_id         = module.parent_zone.zone_id
  name            = local.parent_domain
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = module.cf_website_main.cf_domain_name
    zone_id                = module.cf_website_main.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "children" {
  for_each = {for k,v in module.child_zone : k => v if k != local.no_cert_logging_domain}
  
  zone_id         = each.value.zone_id
  name            = each.key
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = module.cf_website_main.cf_domain_name
    zone_id                = module.cf_website_main.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "no_ct_domain" {
  for_each = {for k,v in module.child_zone : k => v if k == local.no_cert_logging_domain}
  
  zone_id         = each.value.zone_id
  name            = each.key
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = module.cf_website_no_ct_log.cf_domain_name
    zone_id                = module.cf_website_no_ct_log.cf_hosted_zone_id
    evaluate_target_health = false
  }
}