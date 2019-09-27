<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Introduction](#introduction)
- [Troubleshooting](#troubleshooting)
    - [Overall health](#overall-health)
    - [Fluentd](#fluentd)
    - [PubSub](#pubsub)
    - [pubsubbeat](#pubsubbeat)
    - [ES cluster](#es-cluster)
    - [esc-tools](#esc-tools)
    - [Ideas of things to check (based on previous incidents)](#ideas-of-things-to-check-based-on-previous-incidents)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Fluentd](#fluentd-1)
    - [PubSub](#pubsub-1)
    - [pubsubbeat](#pubsubbeat-1)
    - [ES cluster](#es-cluster-1)
    - [esc-tools](#esc-tools-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Troubleshooting

## ES cluster ##

- how to check cluster state (node stats different between different monitoring tools, to be investigated why):
  - if the cluster is in an unhealthy state it might be shown on the deployment welcome page
  - shards' status is shown on the Elasticsearch tab in the web UI
  - cluster logs in the web UI
  - performance tab on the left hand side in the web UI
  - monitoring metrics are sent to a separate cluster called `gitlab-elastic-monitoring-5x`
    - login to Kibana of that cluster -> Monitoring
  - kopf (deprecated in newer versions of ES):
    - https://022d92a4ba7ff6fdacc2a7182948cb0a.us-central1.gcp.cloud.es.io:9243/_found.no/dashboards/kopf/latest/?location=https://022d92a4ba7ff6fdacc2a7182948cb0a.us-central1.gcp.cloud.es.io:9243#!/cluster
    - credentials are in 1password
  - API:
    - you can query the API using:
      - Elasticsearch web UI (`API Console` on the left)
      - Kibana web UI
      - bash + curl
      - Postman
    - credentials for the API are in 1password (username: elastic)
    - some useful examples:
      - shard status
      - reballancing status
      - shard allocation status: `/_cluster/allocation/explain?pretty`
      - retry shard allocation: `/_cluster/reroute?retry_failed=true`
      - get shards: `/_cat/shards`
      - get index templates: `/_cat/templates?v&s=name`
      - get aliases: `/_aliases`
      - get indeces: `/_cat/indices?v`
      - get shard stats: `/<index_name>/_stats?level=shards`
      - get indices sorted by size: `/_cat/indices?v&s=store.size:desc&h=index,docs.count,store.size`
      - force index rollover: `/<index_name>/_rollover`
      ```json
{
	"index": {
		"lifecycle": {
			"indexing_complete": "true"
		}
	}
}

      ```



      - list indeces with number of docs and storage used: `/_cat/indices?v&s=store.size:desc&h=index,docs.count,store.size`
      - cluster settings: `/_cluster/settings`
      - cluster health: `_cluster/health`
      - `_cat`
      - `_stats`

## Ideas of things to check (based on previous incidents) ##

on ES cluster:
- do the nodes have enough disk space?
- are shards being moved?
- are all shards allocated?
- what's the indexing latency?
- what's the cpu/memory/io usage?

# Failover and Recovery procedures #

## ES cluster ##

- rollover an index:
  - using API
  - using `esc-tools`
- force shard reassigment:
  - there is a pull back mechanism in ES, i.e. after a few failed attempts to assign shards Elastic will stop trying
  - check if there are unassigned shards
  - make sure there are workers capable of accepting new shards
  - force trigger shard assignment
- moving shards between nodes:
  - if shards are distributed unequally, one node might receive a disproportionate amount of traffic causing high CPU usage and as a result the indexing latency might go up
  - stop routing to the overloaded node and force an index rollover (incoming documents are only saved to new indeces, regardless of the timestamp in the document)
  - trigger shard reballancing -> this might actually not be such a good idea. If the node is already heavily loaded, making it move a shard, which uses even more resources, will only make things worse.
- removing indeces:
  - API call (wildcards accepted)
  - in newer versions of ES this can also be done using Kibana -> Index Management
- restarting ES deployment
- acknowlede all messages in the pubsub queue: `gcloud beta pubsub subscriptions seek testSubscription --time=$(date +%Y-%m-%dT%H:%M:%S)`
