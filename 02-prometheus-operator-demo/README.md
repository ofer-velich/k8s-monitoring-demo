# Running prometheus with the prometheus-operator

## Requiremets:
- minikube
- helm

### Why do we need it:
- Operate all of Prometheus different components and configures them 
- and comes with community standard dashboards and alerting rules
- constantly monitor yoy k8s cluster and provide Prometheus with its correct target configuration

### What is ServiceMonitor - How dose it works:
ServiceMonitor is a Custom Resource Definition (CRD), it's abstract the configuration to targets so prometheus will scrape the metrics endpoint.
The stable/prometheus-operator deploys some services that are used by the ServiceMonitors to scrape the metrics.

![Image of Yaktocat](https://miro.medium.com/max/3592/1*6KI8wlyWwLwPYgt_SP1CCA.png)

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

### Adding Custom dashboards:
Custom dashboards can be imported by using the Grafana Provisioning with sidecar for dashboards.
In short, there is a container that watches all config maps in the monitoring namespace and filters out the ones with the label grafana_dashboard, provisioning them as dashboards

### Adding/Updating prometheus rules:
There is a config-reloader sidecar container for the Alertmanager pod. 

### Inhibition
Watchdog, an alert meant to be always firing. 
In our example we created an inhibition rule to match all .+Overcommit(regex) alerts with the Watchdog, inhibiting them forever.

### References:
https://medium.com/faun/trying-prometheus-operator-with-helm-minikube-b617a2dccfa3

