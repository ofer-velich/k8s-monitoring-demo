#!/bin/bash

# Store your Logz.io credentials
kubectl --namespace=kube-system create secret generic logzio-metrics-secret \
  --from-literal=logzio-metrics-shipping-token=grsGcePbFjEehyvJOumYEXGARHRLdbjx \
  --from-literal=logzio-metrics-listener-host=listener.logz.io


# Store your cluster details
kubectl --namespace=kube-system create secret generic cluster-details \
  --from-literal=kube-state-metrics-namespace=monitoring \
  --from-literal=kube-state-metrics-port=8080 \
  --from-literal=cluster-name=demo-cluster

# Deploy
kubectl --namespace=kube-system create -f https://raw.githubusercontent.com/logzio/logz-docs/master/shipping-config-samples/k8s-metricbeat.yml