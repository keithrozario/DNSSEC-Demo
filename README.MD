# DNSSEC Demo on AWS Route53


1. [Introduction](#Introduction)
2. [Installation](#Installation)
3. [Created Domains](#Created-Domains)
    * [Parent Domain](#Parent-Domain)
    * [Double DS Domain](#Double-DS-Domain)
    * [Bad Key Domain](#Bad-Key-Domain)
4. [Testing](#Testing)
5. [Additional Reading](#Additional-Reading)


# Introduction

This repo will run a Demo for DNSSEC on Route53.

The demo includes:

* Creating a `parent` zone, with 3 child zones.
* Creating 3 `child` zones, and setting up the NS records in the parent to point to the right Hosted Zones.
* Enabling DNSSEC on the `parent` and `child` zones.
    * All zones utilize the same KMS key as the KSK to save cost
    * Demo will create DS records in the parent zone for the child zones
* Creating a simple Cloudfront Distribution to host a HTML page for both `parent` and `child` zones
    * All zones point to the same Cloudfront Distribution
    * Cloudfront distribution uses an S3 bucket as the origin, accessed via OAI

It does not include:
* Registering DS record in the `parent` top level zone
* Creating NS entries in the `parent` top level zone for the parent (not necessary if this is a root domain e.g. `example.com`)

# Installation

To setup demo, modify the contents of the `locals.tf`

**parent_domain**    : The `parent` domain  
**child_domains**    : List of `child` domains  
**double_ds_domain** : This domain will have 2 DS records in the parent zone (must be in child_domains)  
**bad_key_domain**   : This domain will have an invalid DS record in the parent zone (must be in child_domains)

```hcl
locals {
  parent_domain    = "parent.keithrozario.com"
  double_ds_domain = "double-ds.parent.keithrozario.com"
  bad_key_domain   = "bad-key.parent.keithrozario.com"
  child_domains = toset([
    "bad-key.parent.keithrozario.com",
    "working.parent.keithrozario.com",
    "double-ds.parent.keithrozario.com"
  ])
}
```

To install:

    $ terraform init
    $ terraform apply

# Created Domains

We create a parent domain and child domain, to allow us to setup DS records within the resources deployed by the script rather than having to go to registrars or gTLDs or CCTLDs.

## Parent Domain
This is the `parent` domain that host all `child` domains. The Parent domain is where we will register the DS records and NS records for the child domains. 

## Double DS Domain
To facilitate registrar migration, occassionally we can have a single domain with multiple DS records in the parent domain. The [DNSSEC RFC](https://www.rfc-editor.org/rfc/rfc6840#section-5.11) states that:

>  Validators SHOULD accept any single valid path.  They SHOULD NOT insist that all algorithms signaled in the DS RRset work, and they MUST NOT insist that all algorithms signaled in the DNSKEY RRset work.  A validator MAY have a configuration option to perform a signature completeness test to support troubleshooting.

## Bad Key Domain

This record has it's DS record intentionally set wrong. This means that the DNS resolution with fail DNSSEC validation.

# Testing

To test this, you can visit all `child` domains using your browser. All domains should work, **except** for the bad key domain.

## Additional Testing

    $ dig parent.keithrozario.com +dnssec

    ; <<>> DiG 9.10.6 <<>> DS double-ds.parent.keithrozario.com +dnssec
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51640
    ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags: do; udp: 1232
    ;; QUESTION SECTION:
    ;double-ds.parent.keithrozario.com. IN	DS

    ;; ANSWER SECTION:
    double-ds.parent.keithrozario.com. 60 IN DS	12345 13 2 B8574CB22E4D99B1BBB1E76E47E7CABB664E58D344C40F02EC59E293 845779EC
    double-ds.parent.keithrozario.com. 60 IN DS	51778 13 2 B8574CB22E4D99B1BBB1E76E47E7CABB664E58D344C40F02EC59E293 845779EB
    double-ds.parent.keithrozario.com. 60 IN RRSIG	DS 13 4 60 20220307051936 20220307031836 48610 parent.keithrozario.com. VIXm60aUJekx2YSSxGnsm5mMdIyVH6LA4HgQNkYwMbcZn5mitxFtYfos Xg0E1YBflt3zD1LLpuF+7TH8kFeJBw==

    ;; Query time: 416 msec
    ;; SERVER: 1.1.1.1#53(1.1.1.1)
    ;; WHEN: Mon Mar 07 12:18:36 +08 2022
    ;; MSG SIZE  rcvd: 277


Testing the bad key (note the 'status SERVFAIL'):

    $ dig bad-key.parent.keithrozario.com +dnssec

    ; <<>> DiG 9.10.6 <<>> bad-key.parent.keithrozario.com +dnssec
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 42092
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags: do; udp: 1232
    ; OPT=15: 00 09 6e 6f 20 53 45 50 20 6d 61 74 63 68 69 6e 67 20 74 68 65 20 44 53 20 66 6f 75 6e 64 20 66 6f 72 20 62 61 64 2d 6b 65 79 2e 70 61 72 65 6e 74 2e 6b 65 69 74 68 72 6f 7a 61 72 69 6f 2e 63 6f 6d 2e ("..no SEP matching the DS found for bad-key.parent.keithrozario.com.")
    ;; QUESTION SECTION:
    ;bad-key.parent.keithrozario.com. IN	A

    ;; Query time: 356 msec
    ;; SERVER: 192.168.86.1#53(192.168.86.1)
    ;; WHEN: Mon Mar 07 12:15:37 +08 2022
    ;; MSG SIZE  rcvd: 131

# Additional Reading

Info on Record:  
https://docs.infoblox.com/display/NAG8/RRSIG+Resource+Records

How to run commands:  
https://www.cyberciti.biz/faq/unix-linux-test-and-validate-dnssec-using-dig-command-line/

List of major DNSSEC outtages:  
https://ianix.com/pub/dnssec-outages.html

RFC Spec:  
https://www.rfc-editor.org/rfc/rfc6840#section-5.11

Qname minimization (no relevant here, but interesting):  
https://datatracker.ietf.org/doc/html/rfc7816

IETF recommendation for resolver to authoritative server:  
https://datatracker.ietf.org/doc/draft-ietf-dprive-opportunistic-adotq/?include_text=1
https://www.centr.org/news/blog/ietf110-camel-back.html
