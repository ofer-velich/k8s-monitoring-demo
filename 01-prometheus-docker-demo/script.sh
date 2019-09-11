#!/bin/bash

# setup review

# Create the Alertmanager Prometheus and its scrape targets
docker-compose up

# review the scrape targets on the Prometheus targets tab

# query metrics on the Prometheus the graph tab

# review the alerts on the Prometheus the alerts tab

# trigger an alert
docker run --rm -it busybox sh -c "while true; do :; done"

# add datasource on Grafana

# review dashboard on Grapana

# view the alert on slack and on the Alertmanager

docker-compose down

