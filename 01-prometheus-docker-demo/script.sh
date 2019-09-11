#!/bin/bash

# setup review

# Create the Alertmanager Prometheus and its scrape targets
docker-compose up

# review the scrape targets on the Prometheus targets tab

# query metrics on the Prometheus the graph tab

# review the alerts on the Prometheus the alerts tab

# trigger and alert and view it on slack

docker run --rm -it busybox sh -c "while true; do :; done"

# review dashboard on Grapana

docker-compose down