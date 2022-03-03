output name_servers {
    value = aws_route53_zone.this.name_servers
}

output ds_record {
    value = aws_route53_key_signing_key.this.ds_record
}

output zone_id {
    value = aws_route53_zone.this.zone_id
}