output "child_zone" {
  value = module.child_zone
}

output "parent_zone" {
  value = module.parent_zone
}

output "s3_bucket" {
  value = module.website_bucket.bucket_name
}