<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Troubleshooting](#troubleshooting)
    - [Elastic](#elastic)
        - [How to run commands against the API](#how-to-run-commands-against-the-api)
        - [How to check cluster health](#how-to-check-cluster-health)
        - [How to view shards distribution](#how-to-view-shards-distribution)
        - [Current node allocation](#current-node-allocation)
        - [Number of threads](#number-of-threads)
    - [Ideas of things to check (based on previous incidents)](#ideas-of-things-to-check-based-on-previous-incidents)
        - [too many active shards on a single node](#too-many-active-shards-on-a-single-node)
        - [running out of disk space](#running-out-of-disk-space)
        - [shards unallocated](#shards-unallocated)
        - [shards too big](#shards-too-big)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Elastic](#elastic-1)
        - [force shard reassigment:](#force-shard-reassigment)
        - [moving shards between nodes](#moving-shards-between-nodes)
        - [removing indeces](#removing-indeces)
        - [restarting ES deployments](#restarting-es-deployments)
        - [How to move (relocate) shard from one ES instance to another one (ES 5.x)](#how-to-move-relocate-shard-from-one-es-instance-to-another-one-es-5x)
        - [Create new index](#create-new-index)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Troubleshooting

## Elastic

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

### How to run commands against the API

### How to check cluster health

### How to view shards distribution

1. `curl http://localhost:9200/_cat/shards?v`. You can pipe your output to `sort` to see sorted result.
1. To see shards for specific index, you can use `curl http://<es node>:9200/_cat/shards/logstash-2017.04.01?v`. Logstash creates new index everyday with such pattern - `logstash-YYYY.MM.DD`.

### Current node allocation

Show the current node allocation. This will tell you which nodes are available, how many shards each has, and how much disk space is being used/available:

```
curl -s 'localhost:9200/_cat/allocation?v'
```

### Number of threads

Show the current Elasticsearch threads. Look particularly at the number of bulk entries that are queued. If the number is high, data is not being ingested fast enough.
```
curl 'http://localhost:9200/_cat/thread_pool?v'
```
## Ideas of things to check (based on previous incidents) ##

on ES cluster:
- do the nodes have enough disk space?
- are shards being moved?
- are all shards allocated?
- what's the indexing latency?
- what's the cpu/memory/io usage?

### too many active shards on a single node ###

resulting in hot-spotting, we used high cpu usage as an indicator, but it was based on a guess

### running out of disk space ###

for different reasons:
- too much data
- rebalancing taking place

storae usage in the web UI was in red and the absolute value was high (e.g. 99%)

### shards unallocated ###

for different reasons:
- no eligible nodes
- pull back after multiple failed attempts

warning in the web UI about unallocated shards

`/_cluster/allocation/explain?pretty` api call

### shards too big ###

https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7398

# Failover and Recovery procedures #

## Elastic

### force shard reassigment:
  - there is a pull back mechanism in ES, i.e. after a few failed attempts to assign shards Elastic will stop trying
  - check if there are unassigned shards
  - make sure there are workers capable of accepting new shards
  - force trigger shard assignment

### moving shards between nodes
  - if shards are distributed unequally, one node might receive a disproportionate amount of traffic causing high CPU usage and as a result the indexing latency might go up
  - stop routing to the overloaded node and force an index rollover (incoming documents are only saved to new indeces, regardless of the timestamp in the document)
  - trigger shard reballancing -> this might actually not be such a good idea. If the node is already heavily loaded, making it move a shard, which uses even more resources, will only make things worse.


### removing indeces

  - API call (wildcards accepted)
  - in newer versions of ES this can also be done using Kibana -> Index Management

### restarting ES deployments

### How to move (relocate) shard from one ES instance to another one (ES 5.x)
```
curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
    "commands" : [
        {
          "move" : {
                "index" : "logstash-2017.04.01", "shard" : 5,
                "from_node" : "log-es3", "to_node": "log-es4"
          }
        }
    ]
}'

```

### Create new index

```
curl -XPUT localhost:9200/gitlab -d '{
  "settings": {
    "index" : {
      "number_of_shards" : 120,
      "number_of_replicas": 1
    }
  }
}'
```
