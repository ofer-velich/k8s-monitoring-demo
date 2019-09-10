# prometheus-operator demo

What is Operator:
An Operator is an application-specific controller that extends the Kubernetes API. It builds upon the basic Kubernetes resource and controller concepts but includes domain or application-specific knowledge to automate common tasks

What is ServiceMonitor:
ServiceMonitor is a Custom Resource Definition (CRD), it's abstract the configuration to targets so prometheus will scrape the metrics endpoint.
The stable/prometheus-operator deploys some services that are used by the ServiceMonitors to scrape the metrics.

example:
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  namespaceSelector:
    matchNames:
    - default
  endpoints:
  - port: web
    interval: 30s
```

Note - The default selectors configured in this services may not match the labels of your cluster (which is the minikube case)

Operate all of those different components configures then and comes with community standard dashboards and alerting rules 

Custom dashboards:
Custom dashboards can be imported by using the Grafana Provisioning with sidecar for dashboards.
In short, there is a container that watches all config maps in the monitoring namespace and filters out the ones with the label grafana_dashboard, provisioning them as dashboards

Adding/Updating prometheus rules:
There is a config-reloader sidecar container for the Alertmanager pod. If the config was not updated automatically, check logs for errors:

Watchdog - This inhibt rule is a hack from: https://stackoverflow.com/questions/54806336/how-to-silence-prometheus-alertmanager-using-config-files/54814033#54814033
The Watchdog is an alert meant to be always firing. So we created an inhibition rule to match all .+Overcommit(regex) alerts with the Watchdog, inhibiting them forever.

References:
https://medium.com/faun/trying-prometheus-operator-with-helm-minikube-b617a2dccfa3

#Demo
- running prometheus with docker
- running prometheus with the prometheus-operator
- shipping k8s logs using fluentd to logz.io
- monitoring k8s on logz.io 

# Prometheus Overview
{{https://cdn.rawgit.com/prometheus/prometheus/e761f0d/documentation/images/architecture.svg}}

Prometheus is an open source toolkit to monitor and alert
developed by SoundCloud
support for clients in many languages
provides exporters to connect other application (i.e Postgresql, Mysql, ETCD)

#HA
- To run Prometheus in a highly available manner, two (or more) instances need to be running with the same configuration, that means they scrape the same targets, which in turn means they will have the same data in memory and on disk
- In reality this is not entirely true, as the scrape cycles can be slightly different
- For dashboarding this means sticky sessions (using sessionAffinity on a Kubernetes Service) should be used, to get consistent graphs when refreshing.


#Scaling (Sharding And Federation)
- Sharding, It divides the targets Prometheus scrapes into multiple groups, small enough for a single Prometheus instance to scrape
- Functional sharding (recommended), What is meant by functional sharding is that all instances of Service A are being scraped by Prometheus A.
- Prometheus is also able to perform sharding automatically 
- To be able to query all data, Prometheus federation can be used to fan in the relevant data to perform queries and alerting
- There isn't really the notion of a Prometheus cluster. Basically one Prometheus is as big as the machine that you are running it on.
- Hierarchical Federation, This has been proven to be problematic. It resulted in an increased configuration burden, added an additional potential failure point and required complex rules to expose only certain data on the federated endpoint. In addition, that kind of federation does not allow a truly global view, since not all data is available from a single query API.
- no long retention, on local storage there is ultimately a limit on how much historical data can be stored.


Cortex (Weaveworks) - Cortex is an open source SAAS multi-tenant, horizontally scalable version of Prometheus
Thanos (Improbable) 
Vulcan (Digital Ocean) - use push gate way and metric scrapers that push data to kafka that write it to Cassandra store where the Prometheus is reading from

#Storage And retention
Configuring Prometheus storage retention
- `storage.tsdb.retention.size`
- `storage.tsdb.retention.time`

#Remote Storage
- Remote storage Adapters
- Remote read, when configured, Prometheus storage queries (e.g. via the HTTP API) are sent to both local and remote storage, and results are merged.
- Remote writes, work by "tailing" time series samples written to local storage, and queuing them up for write to remote storage.


#Alerting

Rules

Prometheus scrape metrics from monitored targets at regular intervals, defined by the scrape_interval (defaults to 1m). The scrape interval can be configured globally, and then overriden per job. Scraped metrics are then stored persistently on its local storage.

Prometheus has another loop, whose clock is independent from the scraping one, that evaluates alerting rules at a regular interval, defined by evaluation_interval (defaults to 1m). At each evaluation cycle, Prometheus runs the expression defined in each alerting rule and updates the alert state.
thus it will take at least two evaluation cycles before an alert is fired.

An alert can have the following states:
- inactive: the state of an alert that is neither firing nor pending
- pending: the state of an alert that has been active for less than the configured threshold duration
- firing: the state of an alert that has been active for longer than the configured threshold duration

The optional FOR clause:
Alerts without the FOR clause (or set to 0) will immediately transition to firing.
Alerts with the FOR clause will transition first to pending and then firing, 


The Alert Manager
https://github.com/prometheus/alertmanager

- is able to receive alerts through a specific endpoint (not specific to Prometheus). 
- can redirect alerts to receivers 
- grouping of alerts and determine that a similar notification was already sent (deduplicating)
- it also takes care of silencing and inhibition of alerts (Pager integration)
- HA enabled by default. gossip protocol to synchronize instances of an Alertmanager cluster regarding notifications that have been sent out, to prevent duplicate notifications

grouping similar alerts together into a single notification - when the same alert condition occurring on multiple nodes, we may want to receive just one notification that groups all nodes together instead of a single notification per node

The downside of grouping notifications is that it may introduce further delays.
grouping is basically controlled by the following settings:
```
group_by: [ 'a-label', 'another-label' ]
group_wait: 30s  # necessary to eventually group further upcoming alerts that match the same group_by condition
group_interval: 5m #  how long to wait before dispatching further notifications of the same group 
```


#videos
video1
started 2012 sound cloud published on 2015
https://github.com/prometheus/prometheus
can persist over 1,000,000 samples per sec pr cpu core 
Prometheus2.0 show much greater improvements on cpu, mem and disk consumption 

video2
what prometheus is?
Its a monitoring tool with a build in TSDB
support for client liberies and exporters and alerting 
not do logging or tracing
support for local storage but can by hooked with LTS 

graphite statsd are more of an old tools designed to met the needs of a more static environments

Prometheus architecture - image

selling points:
Dimensional data model:
- based on time series metrics (i.e name timestamp and value)
- old (graphite) time series metrics data module is a based on dot separated objects hierarchy 
  example: nginx.ip.1.2.3.4.500.api.http_requests_total
- dimensional data model, metric name with timestamp and key value labels pairs attached
  example: http_requests_total{job=nginx, status_code=500, path=api}
  i.e you can get more complexed and efficient queries, and one metric can be translated to N time series.

example of dot separated objects hierarchy vs dimensional data model:
```
nginx.ip-1-2-3-5-80.home.200.http_requests_total 
http_requests_total{job="nginx",instance="1.2.3.4:80",path="/home",status="200"} http_requests_total{job="nginx",instance="1.2.3.5:80",path="/settings",status="500"} 
```

example of dot separated objects hierarchy vs dimensional data model query:
```
*.nginx.*.*.500.*.http_requests_total 
http_requests_total{job="nginx",status="500"}
```

What’s the ratio of request errors across all service instances? 
```
$ sum by(path) (rate(http_requests_total{status="500"}[5m])) / sum by(path) (rate(http_requests_total[5m])) 

{path="/status"} 0.0039 
{path="/"} 0.0011 
{path="/api/v1/topics/:topic"} 0.087 
{path="/api/v1/topics} 0.0342
```

Query language 
- PomQL Query language, used for queries that you can base dashboards and alerting over it.

Simplicity and Efficiency
- Operational Simplicity
  Single go binary, 
  has no clustering concept, HA is been done by running two identical prometheus servers and alertmanager do the dedup's
  local storage is not always that simple use case. because its faint in size and not durable, if you needed.
- Efficiency
  local storage is efficient, can persist over 1,000,000 samples per sec per cpu core 
  
Service discovery integration 
- needed in today's dynamic environments
- prometuse discover targets using service discovery
	- static
	- cloud service discovery
	- k8s etc
	- consul etc
	- DNS
- in addition to scrape targets, the service discovery can provide target metadata like labels on application type and it's environment
- scrape metrics under the `/metrics` endpoint by default

What are the common metrics we scrape on k8s
- node-exporter expose the machine metrics (cpu load network disk etc)
- cAdvisor expose the container metrics (cpu load network disk etc)
- kube-state-metrics expose state metrics like number of deployment replicas

Huge configuration, for vireos scraping components very hard to maintain 
Having lots of Prometheus servers that need to be in version control 
Its not Multi tenet, 
Managing Grafana Users SSO integration



