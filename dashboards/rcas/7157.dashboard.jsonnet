local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local text = grafana.text;

dashboard.new(
  '2019-07-01 Degraded performance on GitLab.com',
  schemaVersion=16,
  tags=['rca','redis-cache'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
  time_from='2019-07-01 00:00:00',
  time_to='2019-07-04 00:00:00',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(layout.grid([
  text.new(
    title='Single core saturation on the redis-cache fleet',
    mode='markdown',
    content=''
  ),
  basic.saturationTimeseries(
    title="Single core saturation on the redis-cache fleet",
    query='
      max(1 - rate(node_cpu_seconds_total{environment="$environment", type="redis-cache", mode="idle", fqdn=~"redis-cache-\\\\d\\\\d.*"}[$__interval]))
    ',
    legendFormat='Max Single Core Saturation',
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('Max Single Core Saturation')),

  // ------------------------------------------------------

  text.new(
    title='Redis-cache network traffic',
    mode='markdown',
    content=''
  ),
  basic.networkTrafficGraph(
    title="Single core saturation on the redis-cache fleet",
    sendQuery='
      sum(rate(redis_net_output_bytes_total{environment="$environment", type="redis-cache"}[$__interval]))
    ',
    receiveQuery='
      sum(rate(redis_net_input_bytes_total{environment="$environment", type="redis-cache"}[$__interval]))
    ',
    intervalFactor=2
  ),
], cols=2,rowHeight=10, startRow=1))
+ {
  annotations: {
    list+: [{
      "datasource": "Pagerduty",
      "enable": true,
      "hide": false,
      "iconColor": "#F2495C",
      "limit": 100,
      "name": "GitLab Production Pagerduty",
      "serviceId": "PATDFCE",
      "showIn": 0,
      "tags": [],
      "type": "tags",
      "urgency": "high"
    },
    {
      "datasource": "Pagerduty",
      "enable": true,
      "hide": false,
      "iconColor": "#C4162A",
      "limit": 100,
      "name": "GitLab Production SLO",
      "serviceId": "P7Q44DU",
      "showIn": 0,
      "tags": [],
      "type": "tags",
      "urgency": "high"
    },
    {
      "datasource": "Simple Annotations",
      "enable": true,
      "hide": false,
      "iconColor": "#5794F2",
      "limit": 100,
      "name": "Key Events",
      // To be completed...
      "queries": [
      ],
      "showIn": 0,
      "tags": [],
      "type": "tags"
    }]
  },
}
