#!/bin/bash

# Overview of the prometheus-operator

# Minikube setup (starting minikube with extra-config to start controller-manager and the scheduler listening on 0.0.0.0 (all interfaces) so Prometheus can scrape it. Etcd (default to listens on 127.0.0.1) is more complicated)
minikube start --vm-driver=hyperkit \
--memory=4096 \
--bootstrapper=kubeadm \
--extra-config=scheduler.address=0.0.0.0 \
--extra-config=controller-manager.address=0.0.0.0

# Helm Initialization
kubectl create serviceaccount tiller --namespace kube-system

kubectl create clusterrolebinding tiller-role-binding --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller

# --> you should with till tiller pod is up <--

# Installing Prometheus Operator
helm install stable/prometheus-operator --version=4.3.6 --name=monitoring --namespace=monitoring --values=values.yaml

# --> you should with till all pods are up <--

kubectl port-forward -n monitoring prometheus-monitoring-prometheus-oper-prometheus-0 9090 &

kubectl port-forward -n monitoring alertmanager-monitoring-prometheus-oper-alertmanager-0 9093 &

# User: admin
# Pass: prom-operator
kubectl port-forward $(kubectl get pods --selector=app=grafana -n monitoring --output=jsonpath="{.items..metadata.name}") -n monitoring 3000 &

# query all dashboards 
kubectl get configmap --selector grafana_dashboard=1 --namespace=monitoring

