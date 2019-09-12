# Gitlab Certificate Run Books

This is an overview of certificates, where they are used and how they can be replaced in their service.

## General info

- COMODO has renamed to Sectigo, those names might get used interchangeably in this document. Any Certificate that is listed as issued by COMODO will in the future be issued by Sectigo.
- Our primary certificate source is [SSMLate](https://sslmate.com/console/orders/).
  - Using the above link it is possible to retrieve the current certificate file for each CN listed there.
  - Those files are permanent links to the public chain of the certificate. The key is *not* part of that chain.
- [There is an effort to automate certificate rotation](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6778). Certificates/Services where that automation has been implemented will be marked accordingly.

## Deployment and replacement strategies

Currently we have multiple ways of deploying certificates. Please see the `Management` and `Item` columns to find the management process and item to edit according to that documentation.

- [Chef Vault][cv]
- [Fastly][f]

## Certificates and their use

### Certificates currently managed by the GitLab Infrastructure team:
| domain | issuer |  Comments | Management | Items |
| ------ | ------ | ----------- | -------- |
| about-src.gitlab.com | COMODO RSA Domain Validation Secure Server CA | about.gitlab.com origin certificate | [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `ssl_certificate`, `ssl_key` |
| about.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | CDN Certificate for about.gitlab.com | [Fastly][f] | |
| canary.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Canary direct access |
| ce.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Redirect to CE repo, hosted on about-src. | [Fastly][f] & [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[ce.gitlab.com][ssl_certificate]`, `[ce.gitlab.com][ssl_key]` |
| chef.gitlab.com | COMODO RSA Domain Validation Secure Server CA | Chef server |
| contributors.gitlab.com | COMODO ECC Domain Validation Secure Server CA | Redirect to gitlab.biterg.io, hosted on fastly |
| customers.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Customer management |
| dashboards.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Public grafana |
| dashboards.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | Internal grafana |
| dev.gitlab.org | COMODO RSA Domain Validation Secure Server CA | dev instance |
| docs.gitlab.com | COMODO RSA Domain Validation Secure Server CA | GitLab documentation |
| dr.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Disaster recovery instance |
| ee.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Redirect to EE repo, hosted on about-src., no CDN | [Fastly][f] & [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[ee.gitlab.com][ssl_certificate]`, `[ee.gitlab.com][ssl_key]` |
| forum.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | GitLab forum |
| gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Duh |
| gitlab.org | COMODO RSA Domain Validation Secure Server CA | Redirect to about.gitlab.com, hosted on fastly (about-src) |
| hub.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | redirects to https://lab.github.com/ (https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6667) | [Fastly][f] & [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[hub.gitlab.com][ssl_certificate]`, `[hub.gitlab.com][ssl_key]` |
| jobs.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | redirects to https://about.gitlab.com/jobs/ Hosted on about-src, without CDN | [Fastly][f] & [Chef Vault][cv] | data bag: `about-gitlab-com`, item: `_default`, fields: `[jobs.gitlab.com][ssl_certificate]`, `[jobs.gitlab.com][ssl_key]` |
| license.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| log.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | |
| monitor.gitlab.net | COMODO RSA Domain Validation Secure Server CA | redirects to dashboards.gitlab.net |
| monitor.gitlab.net | Amazon Server CA 1B | New cert valid until end of 2020 - use unclear |
| next.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Canary selector page |
| next.staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Does not work as of now, but should be fixed to work in the future |
| nonprod-log.gitlab.net | Sectigo ECC Domain Validation Secure Server CA | non prod logs |
| ops.gitlab.net | COMODO RSA Domain Validation Secure Server CA | ops instance |
| packages.gitlab.com | COMODO RSA Domain Validation Secure Server CA | packagecoud instance |
| plantuml.pre.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | Plantuml renderer |
| pre.gitlab.com | COMODO RSA Domain Validation Secure Server CA | prerelease instance |
| prometheus-01.us-east1-c.gce.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | |
| prometheus-01.us-east1-d.gce.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | |
| prometheus.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| redash.gitlab.com | COMODO RSA Domain Validation Secure Server CA | hosted on version. |
| registry.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| registry.pre.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| registry.staging.gitlab.com | COMODO RSA Domain Validation Secure Server CA | |
| sentry.gitlab.net | COMODO RSA Domain Validation Secure Server CA | |
| staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | staging instance |
| status.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | statuspage.io |
| support.gitlab.com | Let's Encrypt Authority X3 | General zendesk |
| swedish.chef.gitlab.com | COMODO RSA Domain Validation Secure Server CA | Chef server, that hosts some remains of GitHost.io |
| swedish.chef.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| user-content.staging.gitlab-static.net | Sectigo ECC Domain Validation Secure Server CA | |
| version.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | |
| *.about-src.gitlab.com | COMODO RSA Domain Validation Secure Server CA | |
| *.about.gitlab.com | COMODO RSA Domain Validation Secure Server CA | |
| *.gitlab.io | C=BE, O=GlobalSign nv-sa, CN=AlphaSSL CA - SHA256 - G2 | GitLab pages |
| *.gitter.im | COMODO RSA Domain Validation Secure Server CA | gitter.im is a SAN in that certificate |
| *.gstg.gitlab.io | Sectigo RSA Domain Validation Secure Server CA | GitLab pages on gstg |
| *.pre.gitlab.io | Sectigo RSA Domain Validation Secure Server CA |  Not used. pre is misconfigured to use *.gitlab.io instead. Should be fixed, thus putting in infra section |
| *.qa-tunnel.gitlab.info | Sectigo RSA Domain Validation Secure Server CA | |



Defunct certs (dead hosts, no longer used, etc)

| domain | issuer | valid until | Comments |
| ------ | ------ | ----------- | -------- |
| alerts.gitlabhosted.com | COMODO RSA Domain Validation Secure Server CA | 2020-01-03T23:59:59 | GitHost related |
| alerts.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-24T23:59:59 | Active certificate, but not rolled out to the CN host. |
| allremote.org | Sectigo RSA Domain Validation Secure Server CA | 2020-06-08T23:59:59 | Page 404s with HTTP, and `NET::ERR_CERT_COMMON_NAME_INVALID` on HTTPS. Is a gitlab.io page. |
| canary.staging.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-06T23:59:59 | Connection to host times out |
| canary.staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-09-06T23:59:59 |
| convdev.io | Sectigo RSA Domain Validation Secure Server CA | 2020-05-30T23:59:59 | Current certificate, but not rolled out |
| registry.gke.gstg.gitlab.com | Let's Encrypt Authority X3 | 2019-09-24T17:49:51 | Was retrieved, but is not used. Verified by jarv |
| registry.gke.pre.gitlab.com | Let's Encrypt Authority X3 | 2019-08-26T16:53:33 | Same as `registry.gke.gstg.gitlab.com` |
| registry.gke.staging.gitlab.com | Let's Encrypt Authority X3 | 2019-09-24T18:07:16 | Same as `registry.gke.gstg.gitlab.com` |
| enable.gitlab.com | Let's Encrypt Authority X3 | 2019-10-14T21:09:02 | Site is a 404 |
| geo1.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-02T23:59:59 | Does not resolve |
| geo2.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-15T23:59:59 | Does not resolve |
| gprd.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2020-02-06T23:59:59 | does not resolve |
| gstg.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-04-11T23:59:59 | does not resolve |
| log.gitlap.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-02T23:59:59 | Replaced by log.gitlab.net |
| monkey.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-27T23:59:59 | does not resolve |
| next.staging.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-02-22T23:59:59 | does not resolve |
| performance-lb.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-17T23:59:59 | does not resolve |
| prod.geo.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-08-14T23:59:59 | does not resolve |
| prometheus-01.nyc1.do.gitlab-runners.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2019-11-06T23:59:59 | times out |
| prometheus-2.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | times out |
| prometheus-3.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | times out |
| prometheus-app-01.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-16T23:59:59 | times out |
| prometheus-app-02.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2020-02-16T23:59:59 | times out |
| prometheus.gitlabhosted.com | COMODO RSA Domain Validation Secure Server CA | 2019-11-28T23:59:59 | cert not rolled out to host |
| runners-cache-5.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-06-07T23:59:59 | does not resolve |
| sentry-infra.gitlap.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-26T23:59:59 | connection refused |
| snowplow.trx.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-07-03T23:59:59 | time out |
| sync.geo.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-08-17T23:59:59 | does not resolve |
| *.ce.gitlab-review.app | COMODO ECC Domain Validation Secure Server CA | 2019-10-03T23:59:59 | time out |
| *.ce.gitlab-review.app | Sectigo ECC Domain Validation Secure Server CA | 2020-10-03T23:59:59 | time out |
| *.design.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-04-27T23:59:59 | site uses a LE cert generated by gl pages. Wildcard is not installed. This cert is dead |
| *.dr.gitlab.net | Sectigo ECC Domain Validation Secure Server CA | 2020-01-23T23:59:59 | does not resolve |
| *.ee.gitlab-review.app | COMODO ECC Domain Validation Secure Server CA | 2019-10-03T23:59:59 | times out |
| *.eks.helm-charts.win | Sectigo RSA Domain Validation Secure Server CA | 2020-04-01T23:59:59 | does not resolve |
| *.githost.io | Sectigo RSA Domain Validation Secure Server CA | 2020-05-03T23:59:59 | wildcard is dead (does not resolve) and githost is shut down (but githost.io still reachable) |
| *.gitlab-review.app | COMODO RSA Domain Validation Secure Server CA | 2019-09-10T23:59:59 | does not resolve |
| *.helm-charts.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | times out |
| *.k8s-ft.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | times out |
| *.ops.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-08-15T23:59:59 | Does not appear to be used. geo & registry use a SAN on ops.gitlab.net |
| *.pre.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-10-16T23:59:59 | not used. registry has its own cert |
| *.pre.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-03-05T23:59:59 | does not resolve |
| *.separate-containers.party | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | does not resolve |
| *.single.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-12T23:59:59 | does not resolve |
| *.single.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-09-12T23:59:59 | |
| *.staging.gitlab.io | Sectigo RSA Domain Validation Secure Server CA | 2020-06-25T23:59:59 | Gitlab pages on staging, was not updated on hosts, is it still used? There IS *.gstg.gitlab.io which is working |
| *.testbed.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-03T23:59:59 | does not resolve |

Security Certs

| domain | issuer | valid until | Comments |
| ------ | ------ | ----------- | -------- |
| bouncer.sec.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-02-15T23:59:59 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-09-04T10:13:40 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-09-08T08:59:00 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-10-21T05:48:27 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-10-21T06:16:21 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-11-03T08:38:09 | |
| deps.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-11-07T07:53:21 | |
| deps.staging.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-09-02T09:15:26 | |
| deps.staging.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-09-12T02:57:19 | |
| deps.staging.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-11-01T07:36:33 | |
| deps.staging.sec.gitlab.com | Let's Encrypt Authority X3 | 2019-11-11T01:40:50 | |
| h1.sec.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2019-10-25T23:59:59 | |
| slack-notifier.sec.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-07-03T23:59:59 | |
| network-scanner.gitlap.com | COMODO RSA Domain Validation Secure Server CA | 2019-10-16T23:59:59 | Some DO machine that does nod accept connections, maybe from Sec? |
| network-scanner.gitlap.com | Sectigo RSA Domain Validation Secure Server CA | 2020-10-16T23:59:59 | |

Other Certs (Unknown maintainer)

| domain | issuer | valid until | Comments |
| ------ | ------ | ----------- | -------- |
| federal-support.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-22T23:59:59 | US Federal Zendesk instance |
| federal-support.gitlab.com | Let's Encrypt Authority X3 | 2019-09-29T18:11:39 | |
| learn.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-05-30T23:59:59 | redirects to https://gitlab.lookbookhq.com/users/sign_in |
| page.gitlab.com | CloudFlare, Inc. | | redirect to about. (Non infra managed as CF renews automagically) |
| page.gitlab.com | CloudFlare, Inc. | | |
| prod.pages-check.gitlab.net | COMODO RSA Domain Validation Secure Server CA | 2019-09-19T23:59:59 | only returns HTML with 'This page should be accessible from the IP 35.185.44.232' |
| prod.pages-check.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-09-19T23:59:59 | |
| saml-demo.gitlab.info | Sectigo RSA Domain Validation Secure Server CA | 2020-05-18T23:59:59 | |
| saml-demo.gitlab.info | Let's Encrypt Authority X3 | 2019-10-23T19:46:50 | |
| shop.gitlab.com | Let's Encrypt Authority X3 | 2019-10-09T19:47:35 | Swag shop |
| shop.gitlab.com | CloudFlare, Inc. | | |
| shop.gitlab.com | CloudFlare, Inc. | | |
| translate.gitlab.com | Let's Encrypt Authority X3 | 2019-10-04T02:12:34 | GitLab translation site |
| www.meltano.com | COMODO RSA Domain Validation Secure Server CA | 2019-09-07T23:59:59 | Maybe mananaged by infra? |
| *.cloud-native.win | COMODO RSA Domain Validation Secure Server CA | 2019-11-08T23:59:59 | looks like a k8s cluster |
| *.gprd.gitlab.com | COMODO RSA Domain Validation Secure Server CA | 2020-02-12T23:59:59 | does not resolve, is it used? |
| *.gprd.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-14T23:59:59 |  does not resolve, is it used? |
| *.gstg.gitlab.com | Sectigo RSA Domain Validation Secure Server CA | 2020-04-11T23:59:59 | does not resolve, is it used? |
| *.gstg.gitlab.net | Sectigo RSA Domain Validation Secure Server CA | 2020-05-14T23:59:59 | does not resolve, is it used? |

[cv]: chef_vault.md
[f]: fastly.md
