# delete additional-scrape-configs secret firstly

```bash
kubectl -n d3os-monitoring-system delete secret additional-scrape-configs
```

# create additional-scrape-configs secret from prometheus file

```bash
kubectl -n d3os-monitoring-system create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml
```

# The secrets should be modified both in two places:

1. roles/ks-istio/files/prometheus/prometheus-additional.yaml

2. keep roles/ks-monitor/files/prometheus/prometheus/additional-scrape-configs.yaml

`kubectl get secrets additional-scrape-configs -n d3os-monitoring-system`
