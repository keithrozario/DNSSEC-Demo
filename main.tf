terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  
  cloud {
    organization = "aws-demos"

    workspaces {
      name = "DNSSEC"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

module DNSSEC_Key {
  source = "./kms_key"
  key_description = "DNSSEC KSK"
}

module parent_zone {
  source = "./sub_domain"
  domain = local.parent_domain
  ksk_key_arn = module.DNSSEC_Key.key_arn
}

module child_zone {
  for_each = local.child_domains

  source = "./sub_domain"
  domain = each.key
  ksk_key_arn = module.DNSSEC_Key.key_arn
}

module parent_child_domain_association {
  for_each = module.child_zone

  source = "./parent_child_association"
  parent_zone_id   = module.parent_zone.zone_id
  child_domain = each.key
  child_name_servers = each.value.name_servers
  child_ds_record = each.value.ds_record

}