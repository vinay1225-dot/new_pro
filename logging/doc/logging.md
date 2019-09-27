<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Application logging at gitlab](#application-logging-at-gitlab)
    - [Summary](#summary)
        - [Quick Start](#quick-start)
            - [Production](#production)
            - [PreProd (pre.gitlab.com)](#preprod-pregitlabcom)
            - [Staging](#staging)
            - [.org (dev.gitlab.org)](#org-devgitlaborg)
            - [Runners](#runners)
        - [StackDriver](#stackdriver)
        - [BigQuery](#bigquery)
    - [Overview](#overview)
        - [What are we logging?](#what-are-we-logging)
        - [Overview](#overview-1)
        - [FAQ](#faq)
            - [Why are we using StackDriver in addition to ElasticSearch?](#why-are-we-using-stackdriver-in-addition-to-elasticsearch)
            - [Why are we using pubsub queues instead of sending logs from fluentd directly to Elastic?](#why-are-we-using-pubsub-queues-instead-of-sending-logs-from-fluentd-directly-to-elastic)
            - [How do I find the right logs for my service?](#how-do-i-find-the-right-logs-for-my-service)
            - [A user sees an error on GitLab com, how do I find logs for that user?](#a-user-sees-an-error-on-gitlab-com-how-do-i-find-logs-for-that-user)
            - [Why do we have these annoying json. prefixes?](#why-do-we-have-these-annoying-json-prefixes)
            - [What if I need to query logs older than 30 days?](#what-if-i-need-to-query-logs-older-than-30-days)
        - [Configuration](#configuration)
            - [Cookbooks](#cookbooks)
            - [logs parsers](#logs-parsers)
                - [Elastic mappings](#elastic-mappings)
            - [Role configuration](#role-configuration)
            - [Terraform](#terraform)
            - [Adding a new logfile](#adding-a-new-logfile)
        - [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
            - [Logs have stopped showing up on elastic search](#logs-have-stopped-showing-up-on-elastic-search)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Application logging at gitlab

**IMPORTANT** : Previously production logs were using the `pubsub-production-*` indices, this has changed to `pubsub-rails-*` indices. For more info see the [table](logging.md#what-are-we-logging).

## Summary

**https://log.gprd.gitlab.net**

**https://nonprod-log.gitlab.net**

### Quick Start

_For information about index names and how they map to log files see the
[table](logging.md#what-are-we-logging) below._

#### Production

To find production logs select the corresponding indexes with `pubsub-*-gprd` in the name

* For azure filter by `json.environment: prd`
* For GCP filter by `json.environment: gprd`

#### PreProd (pre.gitlab.com)

The PreProduction environment shares the same ES indexes as staging.
To find PreProd logs select the corresponding indexes with `pubsub-*-gstg` in the name

* Filter by `json.environment: pre`

#### Staging

To find production logs select the corresponding indexes with `pubsub-*-gstg` in the name

* For Azure filter by `json.environment: stg`
* For GCP filter by `json.environment: gstg`


#### .org (dev.gitlab.org)

To find .org logs select the corresponding indexes with `pubsub-*-gstg` in the name

* For azure filter by `json.environment: dev`
* For GCP filter by `json.environment: dev`

#### Runners

To find logs for runners select the `pubsub-syslog-gprd` index.

* For both azure and GCP filter by `json.environment: ci-prd` or `json.environment: ci-stg`.

_Note: Runner logs are unstructured and mixed in with other syslog messages, structured logging tracked with https://gitlab.com/gitlab-org/gitlab-runner/issues/3336_


### StackDriver

All logs listed in the [table](logging.md#what-are-we-logging) below are processed by StackDriver, but
most are excluded from it's indexing for cost reasons. It is sometimes helpful to use
it to search for logs over a 30day interval for the included logs. It also allows
you to do basic queries for strings across all types and find errors.

The current exclusions for StackDriver can be found in [terraform variables.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/shared/gstg-gprd/variables.tf),
search for `sd_log_filters`.

### BigQuery

The `haproxy` logs are also configured to be forwarded to a BigQuery dataset using
a StackDriver sink: [gitlab-production:haproxy_logs](https://console.cloud.google.com/bigquery?organizationId=769164969568&project=gitlab-production&p=gitlab-production&d=haproxy_logs&page=dataset)


## Overview

### What are we logging?

**production.log and haproxy logs are no longer being sent to elasticcloud due because it was overwhelming our cluster, currently these logs are only available in StackDriver**

**All logs not excluded from from StackDriver are stored in stackdriver for 30 days**

**All logs processed by StackDriver are archived object storage for a minimum of 180days even if excluded**

For retention in elasticcloud, see the cleanup script - https://gitlab.com/gitlab-restore/esc-tools/blob/master/cleanup_indices.sh

| name | logfile  | type  | index | stackdriver filter |
| -----| -------- |------ | ----- |--------------------|
| gitaly | gitaly/current | JSON | pubsub-gitaly-inf | |
| pages | gitlab-pages/current | JSON | pubsub-pages-inf | |
| db.postgres | postgresql/current | line regex | pubsub-postgres-inf | |
| db.pgbouncer | gitlab/pgbouncer/current | line regex | pubsub-postgres-inf | |
| workhorse | gitlab/gitlab-workhorse/current | JSON | pubsub-workhorse-inf | |
| rails.api | gitlab-rails/api\_json.log | JSON | pubsub-rails-inf | |
| rails.application | gitlab-rails/application.log | JSON | pubsub-application-inf | |
| rails.audit | gitlab-rails/audit_json.log | JSON | pubsub-rails-inf | |
| rails.auth | gitlab-rails/auth.log | JSON | pubsub-rails-inf | |
| rails.database_load_balancing | gitlab-rails/database_load_balancing.log | JSON | pubsub-rails-inf | |
| rails.geo | gitlab-rails/geo.log | JSON | pubsub-rails-inf | |
| rails.git | gitlab-rails/git_json.log | JSON | pubsub-rails-inf | |
| rails.importer | gitlab-rails/impoter.log | JSON | pubsub-rails-inf | |
| rails.integrations | gitlab-rails/integrations\_json.log | JSON | pubsub-rails-inf | |
| rails.kubernetes | gitlab-rails/kubernetes.log | JSON | pubsub-rails-inf | |
| rails.production | gitlab-rails/production\_json.log | JSON | pubsub-rails-inf | |
| shell | gitlab-shell/gitlab-shell.log | JSON | pubsub-shell-inf | |
| unicorn.current | /var/log/gitlab/unicorn/current | line regex | pubsub-unicorn-inf | |
| unicorn.stderr | /var/log/gitlab/unicorn/unicorn\_stderr.log | line regex | pubsub-unicorn-inf | |
| unicorn.stdout | /var/log/gitlab/unicorn/unicorn\_stdout.log | line regex | pubsub-unicorn-inf | |
| unstructured.production | gitlab-rails/production.log | lines | pubsub-unstructured-inf | label.tag="unstrucctured.production" |
| sidekiq | /var/log/gitlab/sidekiq-cluster/current |  JSON | pubsub-sidekiq-inf | |
| haproxy | /var/log/haproxy.log | syslog | pubsub-haproxy-inf | label.tag="haproxy" |
| nginx.access | /var/log/gitlab/nginx/gitlab\_access.log | nginx | pubsub-nginx-inf | |
| registry | n/a | mix (lines/json) | pubsub-gke-inf | |
| system.auth | /var/log/auth.log | syslog | pubsub-system-inf | |
| system.syslog | /var/log/syslog | syslog | pubsub-system-inf | |
| rails.graphql | /var/log/gitlab/gitlab-rails/graphql_json.log | JSON | pubsub-rails-inf ||
| history.psql | /home/*-db/.psql_history  | | |
| history.irb | /var/log/irb_history/*.log  | | |

### Logging infrastructure

![Overview](./img/logging.png)

Files containing logs are parsed by Fluentd (td-agent). Fluentd runs directly on a number of different VMs across our fleet or as a [daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) inside kubernetes. Fluentd running on VMs is configured to send logs to two destinations: [Stackdriver](https://cloud.google.com/stackdriver/docs/) and [Cloud Pub/Sub](https://cloud.google.com/pubsub/docs/). Fluentd running as a daemonset, sends logs only to Stackdriver.

All logs reaching Stackdriver are saved to GCS using an export sink where they are stored long-term (e.g. 6 months) for compliance reasons and can be read using BigQuery. Kubernetes logs are also forwarded from Stackdriver to Pub/Sub (that's because Fluentd in kubernetes is not forwarding logs to Pub/Sub).

Logs from different components have designated topics in Pub/Sub and each topic has a corresponding subscription. There is a subscriber for each subscription. At the moment of writing we are using pubsubbeat to subscribe to Pub/Sub subscriptions and forward logs to an Elastic cluster.

Pubsubbeat runs on dedicated VMs. The binary pulls logs from a subscription and uploads them to Elastic using the [bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html). The default configuration of Pubsubbeat is to create templates and field mappings in indices. However, we are instead relying on the dynamic mappings created by the Elastic cluster. Some alternatives to Pubsubbeat include: Filebeat, Fluentd, Logstash.

Aliases are referenced by Pubsubbeat when uploading logs to Elastic. When logs reach the Elastic cluster, they are indexed into documents by a worker, the alias name is resolved to an index name and the documents are saved in the index. There should only ever be one active index per alias and the alias should be pointing to that index.

Indices can be managed in different ways (e.g. custom scripts, Curator, ILM). [The ILM plugin](https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-index-lifecycle-management.html) has proved to be particularly useful and has become very popular in recent year, so it was integrated into Elastic. It meets a lot of our requirements so that's what we're using. ILM behavior is configured via policies assigned to indices and ILM config. The plugin triggers an ILM step of an index at a configurable frequency. The indices go through a number of steps, which can be simplified to: warm -> hot -> cold -> delete. Behavior of ILM at each of those steps is defined in the ILM policy. Here's an example policy:
```
{
    "policy": {
        "phases": {
            "hot": {
                "actions": {
                    "rollover": {
                        "max_age": "3d",
                        "max_size": "50gb"
                    },
                    "set_priority": {
                        "priority": 100
                    }
                }
            },
            "warm": {
                "min_age": "1m",
                "actions": {
                    "forcemerge": {
                        "max_num_segments": 1
                    },
                    "allocate": {
                        "require": {
                            "data": "warm"
                        }
					          },
					          "set_priority": {
						            "priority": 50
                    }
                }
            },
            "delete": {
                "min_age": "7d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}
```
Let's say ILM is configured to run every 10 mins and the above policy is assigned to a newly created index. What will happen, is after 10 mins, ILM will trigger the hot phase, which will check the size and age of the index. If the size exceeds 50GB or the age exceeds 3 days, the configured [action](https://www.elastic.co/guide/en/elasticsearch/reference/current/_actions.html) is triggered, which in this case would send a call to the [rollover api](https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-rollover-index.html). The rollover API will mark the current index as non-writable, mark it for the warm phase and create a new index from an index template. This way, we can control for example the size of shards within indices or logs retention period.

Logs (documents) can be viewed in Kibana using index patterns, i.e. when you open the Discover application in Kibana, you can select the index pattern from a drop-down list and all searches you will submit will be performed against all indices matching the index pattern. There are also a number of other features in Kibana we're using: dashboards, saved searches, visualizations, watchers.

Our Elastic clusters have monitoring enabled and the monitoring metrics are forwarding to a separate monitoring cluster.

There is a VM in each environment called `sd-exporter-*`. This VM is created using a generic terraform module https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/generic-sv-with-group . The VM has a chef role assigned to it which downloads and runs the stackdriver exporter https://gitlab.com/gitlab-cookbooks/gitlab-exporters/ . The exporter service runs on a tcp port number 9255. Prometheus is configured through a role in chef-repo to scrape port 9255 on `sd-exporter-*` VMs. Metrics scraped this way are the basis for pubsub alerts.

### FAQ

#### Why are we using StackDriver in addition to ElasticSearch?

We are sending logs to stackdriver in addition to elasticsearch for
longer retention and to preserve logs in object storage for 180days.

#### Why are we using pubsub queues instead of sending logs from fluentd directly to Elastic?

We use it for two reasons. Firstly, to handle situations when our log sources emit more logs than Logstash/Elasticsearch can ingest at real time. In this scenario, pubsub serves the role of a buffer. Secondly, we were overloading Elastic Cloud with the number of connections. Thus, having only a few pubsubbeats helps to reduce the overhead of separate connnections.

#### How do I find the right logs for my service?

* Navigate to https://log.gitlab.net
* Select the appropriate index (see chart above).
  * Azure production and GCP production logs are in the *gprd* `*-gprd*` indexes
  * Azure staging and GCP staging logs are in the *gstg* `*-gstg*` indexes
* Optionally filter by environment if you only want to see logs for azure or gcp.
  * `+json.environment: prd` for Azure production
  * `+json.environment: gprd` for Google production

#### A user sees an error on GitLab com, how do I find logs for that user?

* Select the `pubsub-production-inf-grpd*` index
* Search for `+json.username: <user>`

#### Why do we have these annoying json. prefixes?

They are created by https://github.com/GoogleCloudPlatform/pubsubbeat , I don't see a way we can remove them without forking the project.

#### What if I need to query logs older than 30 days?

See [logging_gcs_archive_bigquery.md](logging_gcs_archive_bigquery.md) for
instructions on loading logs into `BigQuery` from their GCS archive files.

### Configuration

#### Cookbooks

There are three cookbooks that configure logging on gitlab.com

* gitlab-proxy - Sets up the nginx proxy so that users can access elastic cloud via log.gitlab.net
* gitlab_fluentd - Sets up td-agent on all nodes, forwards logs to pubsub topics.
* gitlab-elk - Sets up the pubsub beat which reads from the topics and forwards to elastic cloud.

#### logs parsers

##### Elastic mappings

We are utilizing dynamic mappings in Elastic for majority of field mappings. In selected few cases where the mappings need to be adjusted we use mappings added to index templates.

In the past, we used static mappings in logsearch, dynamic mappings generated by pubsubbeat.

#### Role configuration

* There is a [single role for all pubsub beats](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/gprd-infra-pubsub.json) per environment, the index is determined by the hostname which allows it to be dyamic.
* Add `recipe[gitlab_fluentd::<type>]` to the corresponding role to enable td-agent for the template
* The [ops proxy role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/ops-infra-proxy.json) configures the proxy vm that is the reverse proxy for elastic cloud.


#### Terraform

Pub/Sub Topics are managed by terraform (specifically,
[the pubsubbeat module](https://gitlab.com/gitlab-com/gl-infra/terraform-modules/google/pubsubbeat)).

Pub/Sub Subscriptions should be automatically created by the pubsubbeat service
on each pubsub host. If subscriptions get misconfigured (e.g. topics appear
as `_deleted-topic_`) you can delete them and restart the pubsubbeat services to
re-create them.

#### Adding a new logfile

* Decide whether you want a new pubsub topic (which means a new index) or use an existing one
* If you want to use an existing index simply update one of [fluentd templates](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/tree/master/templates/default) and add a section for the new log.
* If youw ant to create a new index, first modify the `variables.tf` of the `gprd` and `gstg` environment so that there is a new topic and a new pubsubbeat to monitor it.
* Add a new "name" and "machine type", see this example:

```
variable "pubsubbeats" {
  type = "map"

  default = {
    "names"         = ["gitaly", "haproxy", "pages", "postgres", "production", "system", "workhorse", "geo", "sidekiq", "api"]
    "machine_types" = ["n1-standard-8", "n1-standard-8", "n1-standard-4", "n1-standard-4", "n1-standard-8", "n1-standard-8", "n1-standard-8", "n1-standard-4", "n1-standard-8", "n1-standard-4"]
  }
}
```

* Note: try to use a small instance type and increase it if necessary.
* Run terraform
* If you are using a new index you will need to add a [new template to fluentd](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/tree/master/templates/default).
* After the template is created, add the recipe to the nodes that have the logfile.


### Monitoring and Troubleshooting

* To ensure that pubsub messages are being consumed and sent to elasticsearch see the [stackdriver pubsub dashboards](https://app.google.stackdriver.com/monitoring/1088234/logging-pubsub-in-gprd?project=gitlab-production)
* Monitoring of td-agent (TBD) https://gitlab.com/gitlab-com/migration/issues/390
* Monitoring of pubsub (TBD) https://gitlab.com/gitlab-com/migration/issues/389

#### Logs have stopped showing up on elastic search

* Find the appropriate beat for the index, look for the vm that matches the index name
* SSH to the vm and look at the `/var/log/pubsubbeat/current` logfile to see if there are any errors.
* If there are no errors check out the `/var/log/tg-agent` logfile on one of the nodes sending logs.
