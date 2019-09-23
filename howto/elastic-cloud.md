# Elastic Cloud

**Elastic Vendor Tracker**: https://gitlab.com/gitlab-com/gl-infra/elastic/issues

Instead of hosting our own elastic search cluster we are using a cluster managed by elastic.co. Our logs are forwarded to it via pubsub beat (see [howto/logging.md](howto/logging.md)).

Current capacity:
* 3 zones
* 5 nodes per zone (total 15)
* 64GiB RAM, 1.5TiB storage per node

## Logging cluster set up

1. Go to Elastic Cloud web UI, login using credentials in 1password
1. Create a deployment:
    1. in GCP
    1. region closest to the rest of our infra (US Central 1)
    1. use latest version of Elastic
    1. hot-warm architecture
    1. Customize deployment:
        1. set VM spec and number for worker nodes
        1. set VM spec for Kibana
    1. Configure index management (keep the default settings)
    1. save password for user `elastic` in 1password (rotate if necessary)
1. Create users and their roles using Kibana
    1. pubsubuser
    1. log-proxy
1. Create ILM policy using a script in esc-tools
1. Create index templates, alias and first index using a script in esc-tools
1. Start sending logs to the cluster
1. Configure index patterns in Kibana (logs have to be present in the cluster):
  - where possible, use json.time (timestamp of the log) rather than timestamp (when the log was received by the cluster)
  - it's currently impossible to configure index patterns through api: https://github.com/elastic/kibana/issues/2310 and https://github.com/elastic/kibana/issues/3709

## Configure Storage Watermarks

When reaching the storage low-watermark on a node, shards will be moved to another node but if all nodes have reached the low-watermark, the cluster will stop storing any data. As per suggestion from Elastic (https://gitlab.com/gitlab-com/gl-infra/production/issues/616#note_124839760) we should use absolute byte values instead of percentages for setting the watermarks and, given the actual shard sizes, we should leave enough headroom for writing to shards, segment merging and node failure.

Current configuration:
* high watermark: 200gb
* low watermark: 150gb

(I believe `gb` means GiB, but can't find a reference.)

### Setting Storage Watermarks

```
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.disk.watermark.low": "200gb",
    "cluster.routing.allocation.disk.watermark.high": "150gb"
  }
}
```


## Resizing cluster ##

### Adding new availability zones ###

https://www.elastic.co/guide/en/cloud-enterprise/current/ece-resize-deployment.html

Adding and removing availability zones was tested. elastic.co decides whether to have a dedicated VM for master or to nominate master from among the data nodes. The number of availability zones determines in how many zones there will be data nodes (you might actually end up with more VMs if elastic.co decides to run master on a dedicated node).

### Resizing instances ###

The way it works is new machines are created with the desired spec, they are then brought online, shards are moved across and once that is complete the old ones are taken offline and removed. This worked very smoothly.

We can scale up and down. Resizing is done live.

## Monitoring ##

Because Elastic Cloud is running on infrastructure that we do not manage or have access to, we cannot use our exporters/Prometheus/Thanos/Alertmanager setup. For this reason, the only available option is to use Elasticsearch built-in monitoring that is storing monitoring metrics in Elasticsearch indices. In production environment, it makes sense to use a separate cluster for storing monitoring metrics (if metrics were stored on the same cluster, we wouldn't know the cluster is down because monitoring would be down as well).

There are 3 places where you check cluster performance:
- ElasticCloud interface (on the deployment page -> Performance)
- in Kibana, in cluster itself (provided monitoring is enabled)
- in Kibana, in the monitoring cluster (provided monitoring is configured to forward metrics to another cluster)

## Alerting ##

Since we cannot use our Alertmanager, Elasticsearch Watchers have to be used for alerting. They will be configured on the Elastic cluster used for storing monitoring indices.

Blackbox probes cannot provide us with sufficient granularity of state reporting.
