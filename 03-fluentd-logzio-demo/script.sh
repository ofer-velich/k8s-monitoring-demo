
# Minikube setup
# (starting minikube with extra-config to start controller-manager and the scheduler listening on 0.0.0.0 (all interfaces) so Prometheus can scrape it. Etcd (default to listens on 127.0.0.1) is more complicated)
minikube start --vm-driver=hyperkit \
--memory=4096 \
--bootstrapper=kubeadm \
--extra-config=scheduler.address=0.0.0.0 \
--extra-config=controller-manager.address=0.0.0.0

# Deploy fluentd
kubectl create secret generic logzio-logs-secret \
    --from-literal=logzio-log-shipping-token=nNQZQoLunsklqksPwbTSkydGNZUiENYT \
    --from-literal=logzio-log-listener=https://listener.logz.io:8071 -n kube-system

kubectl create -f daemonset.yaml

kubectl create -f nginx.yaml

# Create some error/access logs by serfing to the minikube ip
minikube ip