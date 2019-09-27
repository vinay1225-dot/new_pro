

# Troubleshooting

## Overall health

Grafana Logging dashboard: https://dashboards.gitlab.net/d/USVj3qHmk/logging?orgId=1&from=now-7d&to=now

## Fluentd

- check logs for errors:
  - check `./gitlab-fluentd/attributes/default.rb` for location of the logs
  - ssh to the VM which you suspect to be not sending logs
  - check logs for errors

## PubSub

- check Grafana logging dashboard
  - if the number of unacked messages is going up, it means the problem is with taking messages out of the queue
- Google console

## pubsubbeat

- check status of pubsubbeat:
  - ssh to the pubsub VM which you suspect to be not sending logs
  - check service status: `sv status pubsubbeat`
  - check logs for errors:
    - check `./gitlab-elk/attributes/default.rb` for location of the logs
    - check logs for errors

## ILM

# Failover and Recovery procedures #

## Fluentd ##

## PubSub ##

- acknowleding all messages currently in the queue (this is destructive action as all logs in the queue will be lost!)

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

## ILM

### force a rollover
