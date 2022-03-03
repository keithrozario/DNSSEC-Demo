# KMS Key for DNSSEC

This module creates a KMS Key, and attaches the right permissions for Route53 to access and sign ZSKs.

The policy it attaches to the key replicates exactly what AWS automatically generate (as of 02-Mar-2022)