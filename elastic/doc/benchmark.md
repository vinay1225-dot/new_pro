# Stage 1 - identifying failure modes #

## historical failures ##

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


## nginx-gprd logs sent to a tiny cluster ##

### shards too big ###

https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7398

# Stage 2 - finding the right shard size #
