# Running prometheus with docker

## Requiremets:
- Docker compose

## Prometheus Overview:

![Image of Yaktocat](https://cdn.rawgit.com/prometheus/prometheus/e761f0d/documentation/images/architecture.svg)

### What prometheus is?
- Prometheus is an open source toolkit to monitor and alert with a a buildin TSDB local storage
- Developed by SoundCloud Started 2012 published on 2015
- Do not do logging or tracing
- Support for clients in many languages
- Provides exporters to connect other application (i.e Postgresql, Mysql, ETCD)

### Dimensional data model:
- based on time series metrics (i.e name timestamp and value)
- dimensional data model, metric name with timestamp and key value labels pairs attached. With this multi dimensional data model you can get more complexed and efficient queries, and one metric can be translated to N time series.

Example of dot separated objects hierarchy (graphite etc) vs dimensional data model (prometheus):
```
nginx.ip-1-2-3-5-80.home.200.http_requests_total 
http_requests_total{job="nginx",instance="1.2.3.4:80",path="/home",status="200"} http_requests_total{job="nginx",instance="1.2.3.5:80",path="/settings",status="500"} 
```

Example of dot separated objects hierarchy vs dimensional data model query:
```
*.nginx.*.*.500.*.http_requests_total 
http_requests_total{job="nginx",status="500"}
```

### Query language 
- PomQL Query language, used for queries that you can base dashboards and alerting over it.

What’s the ratio of request errors across all service instances? 
```
$ sum by(path) (rate(http_requests_total{status="500"}[5m])) / sum by(path) (rate(http_requests_total[5m])) 

{path="/status"} 0.0039 
{path="/"} 0.0011 
{path="/api/v1/topics/:topic"} 0.087 
{path="/api/v1/topics} 0.0342
```

### Simple to setup
- Single go binary, 
- Has no clustering concept, HA is been done by running two identical prometheus servers and alertmanager do the dedup's. 
- local storage is efficient enough for small deployments, can persist over 1,000,000 samples per sec per cpu core.
- disclaimer: local storage is not always that simple use case. because its faint in size and not durable, if you needed (even in small deployments). 
  
### Service discovery integration 
- prometheus discover targets using service discovery integration (k8s consul etc)
- in addition to scrape targets, the service discovery can provide target metadata like labels on application type and it's environment
- scrape metrics under the `/metrics` endpoint by default

### What are the common metrics we scrape on k8s
- node-exporter expose the machine metrics (cpu load network disk etc)
- cAdvisor expose the container metrics (cpu load network disk etc)
- kube-state-metrics expose state metrics like number of deployment replicas

### Downsides
- On HA dashboarding need to have sticky sessions
- Huge configuration, for lots scraping components very hard to maintain or to troubleshot on a downtime 
- On large federated hierarchy deployments:
    - Its more hard to get queries to target the correct shard 
    - Its more hard to have cluster services wide holistic view from a single query.
    - Its result in an increased configuration burden, 
    - Add an additional potential failure point
    - Security, Required complex rules to expose only certain data on the federated endpoint. 
- No long retention, on local storage there is ultimately a limit on how much historical data can be stored.    
- Its not Multi tenet system 
- Managing Grafana Users SSO integration

## Operating prometheus 

### HA
- To run Prometheus in a highly available manner, two (or more) instances need to be running with the same configuration, that means they scrape the same targets, which in turn means that they will have the same data in memory and on disk.
- disclaimer: In reality this is not entirely true, as the scrape cycles can be slightly different
- For dashboarding this means sticky sessions (using `sessionAffinity` on a Kubernetes Service) should be used, to get consistent graphs when refreshing.

### Scaling (Sharding And Federation)
- Single Prometheus server can only scale verticaliy. With Sharding, you can divide Prometheus servers into multiple groups, so each group is small enough for a single Prometheus instance to scrape
- Functional sharding (recommended) meaning, all instances of Service A are being scraped by Prometheus A.
- Automatically sharding 
- To be able to query and alert on sharded deployment, Prometheus federation can be used to fan in the relevant servers. 

### Storage And retention
Configuring Prometheus storage retention
- `storage.tsdb.retention.size`
- `storage.tsdb.retention.time`

### Remote Storage
- Remote storage Adapters
- Remote read, when configured, storage queries are sent to both local and remote storage, and results are merged.
- Remote writes, work by "tailing" time series samples written to local storage, and queuing them up for write to remote storage.

### Examles
Cortex (Weaveworks) - Cortex is an open source SAAS multi-tenant, horizontally scalable version of Prometheus
Thanos (Improbable) 
Vulcan (Digital Ocean) - use push gate way and metric scrapers that push data to kafka that write it to Cassandra store where the Prometheus is reading from

## Alerting

### Rules

- `scrape_interval` Prometheus scrape metrics from monitored targets (defaults to 1m)
- `evaluation_interval` another independent loop, evaluates alerting rules at a regular interval, defined by evaluation_interval (defaults to 1m)
- in each evaluation loop Prometheus runs the expression defined in each alerting rule and updates the alert state.
- note: it will take at least two evaluation cycles before an alert is fired.

An alert can have the following states:
- inactive: the state of an alert that is neither firing nor pending
- pending: the state of an alert that has been active for less than the configured threshold duration
- firing: the state of an alert that has been active for longer than the configured threshold duration

The optional FOR clause:
- Alerts without the FOR clause (or set to 0) will immediately transition to firing.
- Alerts with the FOR clause will transition first to pending and then firing, 

### The AlertManager
- is able to receive alerts through a specific endpoint (not specific to Prometheus). 
- can redirect alerts to receivers 
- grouping of alerts and determine that a similar notification was already sent (deduplicating)
- it also takes care of silencing and inhibition of alerts (Pager integration)
- HA enabled by default. gossip protocol to synchronize instances of an Alertmanager cluster regarding notifications that have been sent out, to prevent duplicate notifications
- disclaimer: The downside of grouping notifications is that it may introduce further delays.

grouping is basically controlled by the following settings:
```
group_by: [ 'a-label', 'another-label' ]
group_wait: 30s  # necessary to eventually group further upcoming alerts that match the same group_by condition
group_interval: 5m #  how long to wait before dispatching further notifications of the same group 
```


