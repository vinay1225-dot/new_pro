<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Troubleshooting](#troubleshooting)
    - [Overall health](#overall-health)
    - [Fluentd](#fluentd)
    - [PubSub](#pubsub)
    - [pubsubbeat](#pubsubbeat)
    - [Elastic](#elastic)
    - [ILM](#ilm)
- [Failover and Recovery procedures](#failover-and-recovery-procedures)
    - [Fluentd](#fluentd-1)
    - [PubSub](#pubsub-1)
        - [Acknowledge all messages in a queue](#acknowledge-all-messages-in-a-queue)
    - [pubsubbeat](#pubsubbeat-1)
    - [Elastic](#elastic-1)
    - [ILM](#ilm-1)
        - [force a rollover](#force-a-rollover)
        - [mark an index as complete](#mark-an-index-as-complete)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



# Troubleshooting

## Overall health

Grafana Logging dashboard: https://dashboards.gitlab.net/d/USVj3qHmk/logging?orgId=1&from=now-7d&to=now

## Fluentd

- check fluentd logs for errors:
  - check `./gitlab-fluentd/attributes/default.rb` for location of the logs
  - ssh to the VM which you suspect to be not sending logs
  - check logs for errors

## PubSub

- check Grafana logging dashboard
  - if the number of unacked messages is going up, it means the problem is with taking messages out of the queue
- check logs related to: pubsub, pubsub topic, pubsub subscription in Stackdriver
- pubsub monitoring graphs in Google console

## pubsubbeat

- check status of pubsubbeat:
  - ssh to the pubsub VM which you suspect to be not sending logs
  - check service status: `sv status pubsubbeat`
  - check the process is running, e.g. `ps aux | grep pubsubbeat`
  - check logs for errors:
    - check `./gitlab-elk/attributes/default.rb` for location of the logs
    - check logs for errors
- check cpu usage on the VM

## Elastic

for Elastic troubleshooting procedures see (./elastic/doc/troubleshooting/README.md)[../../../elastic/doc/troubleshooting/README.md]

## ILM

- in Kibana, go to: Management -> Index Management -> if there are ILM errors there will be a notification box displayed above the search box
- in Elastic Cloud web UI:
  - go to the deployment and check it's health
  - check Elastic logs for any errors
- in the monitoring cluster:
  - check cluster health
  - check index size

# Failover and Recovery procedures #

## Fluentd ##

## PubSub ##

### Acknowledge all messages in a queue

Acknowleding all messages currently in the queue is a destructive action (all logs in the queue will be lost!).

`gcloud beta pubsub subscriptions seek <subscription_name> --time=$(date +%Y-%m-%dT%H:%M:%S)`

https://cloud.google.com/pubsub/docs/replay-overview

## pubsubbeat ##

- restart pubsubbeat:
  - `sv status pubsubbeat`   # see how long it's been running
  - `sv restart pubsubbeat`
  - `sv status pubsubbeat`   # see how long it's been running
- stop pubsubbeat:
  - `sv status pubsubbeat`
  - `sv stop pubsubbeat`
  - `sv status pubsubbeat`
  - if it's still running:
    - it might actually still be shutting down gracefuly, for example waiting until all uploads to ES are finished, check logs
    - if it's not doing anything or you absolutely have to kill it now: `kill -9 <pubsubbeat_pid>` PLEASE BE SUPER CAREFUL WITH THIS COMMAND AND ONLY USE IF YOU HAVE NO OTHER CHOICE!

## Elastic

for Elastic recovery procedures see (./elastic/doc/troubleshooting/README.md)[../../../elastic/doc/troubleshooting/README.md]

## ILM

### force a rollover

- rollover an index:
  - using API
  - using `esc-tools`

### mark an index as complete
