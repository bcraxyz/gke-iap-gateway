#!/bin/bash

ZONE="YOUR_ZONE"

# Delete all Kubernetes resources
kubectl delete -f gateway-httproute-grants.yaml
kubectl delete -f services-backendpolicy.yaml
kubectl delete -f deployment.yaml
kubectl delete -f app-code-configmap.yaml

# Delete all secrets
kubectl delete secret webapp-tls-secret -n gateway
kubectl delete secret iap-oauth-secret -n app1
kubectl delete secret iap-oauth-secret -n app2

# Delete all namespaces
kubectl delete namespace gateway
kubectl delete namespace app1
kubectl delete namespace app2

# Release the global static IP
gcloud compute addresses delete webappgw-static-ip --global --quiet

# Delete the GKE cluster
gcloud container clusters delete webappgw-cluster --zone "$ZONE" --quiet
