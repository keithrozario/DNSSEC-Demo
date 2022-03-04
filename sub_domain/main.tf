resource "aws_route53_zone" "this" {
  name = var.domain
  force_destroy = true
}

## Turn on DNSSEC for Parent Zone
resource "aws_route53_key_signing_key" "this" {
  hosted_zone_id             = aws_route53_zone.this.id
  key_management_service_arn = var.ksk_key_arn
  name                       = "KSK"
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  depends_on = [
    aws_route53_key_signing_key.this
  ]
  hosted_zone_id = aws_route53_key_signing_key.this.hosted_zone_id
}

## Logging
resource "aws_cloudwatch_log_group" "this" {
  name              = "/dnssec-demo/${var.domain}"
  retention_in_days = 7
}

data "aws_iam_policy_document" "dnssec-demo-route53-query-logging-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    # setting to arn of log group causes redeploy everytime
    resources = [
      "arn:aws:logs:us-east-1:475859042614:log-group:/dnssec-demo/*:*"
    ]

    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "dnssec-demo-route53-query-logging-policy" {
  policy_document = data.aws_iam_policy_document.dnssec-demo-route53-query-logging-policy.json
  policy_name     = "dnssec-demo-route53-query-logging-policy"
}

resource "aws_route53_query_log" "this" {
  depends_on = [aws_cloudwatch_log_resource_policy.dnssec-demo-route53-query-logging-policy]
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.this.arn
  zone_id                  = aws_route53_zone.this.zone_id
}