locals {
  parent_domain    = "parent.keithrozario.com"
  double_ds_domain = "double-ds.parent.keithrozario.com"
  bad_key_domain   = "bad-key.parent.keithrozario.com"
  no_cert_logging_domain = "no-ct.parent.keithrozario.com"
  child_domains = toset([
    "bad-key.parent.keithrozario.com",
    "working.parent.keithrozario.com",
    "double-ds.parent.keithrozario.com",
    "no-ct.parent.keithrozario.com"
  ])
}