#!/bin/bash

# Authenticate with Google Cloud
gcloud auth login

# Set the active project
gcloud config set project YOUR_PROJECT_ID

# Create a GKE cluster with secure and private networking settings
gcloud container clusters create webappgw-cluster \
  --zone YOUR_ZONE \
  --subnetwork YOUR_SUBNET \
  --num-nodes 2 \
  --release-channel stable \
  --enable-network-policy \
  --enable-shielded-nodes \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --enable-private-nodes \
  --enable-ip-alias \
  --enable-master-authorized-networks \
  --master-authorized-networks=$(curl -s ifconfig.me)/32 \
  --master-ipv4-cidr 172.16.0.0/28 \
  --enable-intra-node-visibility

# OPTIONAL: Update master authorized networks if needed
gcloud container clusters update webappgw-cluster \
  --zone YOUR_ZONE \
  --enable-master-authorized-networks \
  --master-authorized-networks=$(curl -s ifconfig.me)/32

# Get cluster credentials for kubectl access
gcloud container clusters get-credentials webappgw-cluster --zone YOUR_ZONE

# Reserve a global static IP for the ingress
gcloud compute addresses create webappgw-static-ip --global

# Display the allocated static IP address
gcloud compute addresses describe webappgw-static-ip --global

# Create namespaces
kubectl create namespace gateway
kubectl create namespace app1
kubectl create namespace app2

# Generate dummy TLS cert and key (for Gateway TLS termination placeholder)
openssl genrsa -out dummy.key 2048
openssl req -new -x509 -key dummy.key -out dummy.crt -days 365 -subj "/CN=dummy-cert"

# Create TLS secret in gateway namespace
kubectl create secret tls webapp-tls-secret \
  --cert=dummy.crt \
  --key=dummy.key \
  -n gateway

echo "[✓] Created dummy TLS secret in gateway namespace."

# Clean up the dummy cert files
rm dummy.crt dummy.key

# Create placeholder IAP OAuth secrets
kubectl create secret generic iap-oauth-secret \
  --from-literal=client_id=YOUR-CLIENT-ID \
  --from-literal=client_secret=YOUR-CLIENT-SECRET \
  -n app1

kubectl create secret generic iap-oauth-secret \
  --from-literal=client_id=YOUR-CLIENT-ID \
  --from-literal=client_secret=YOUR-CLIENT-SECRET \
  -n app2

# Apply the ConfigMap (HTML content + Nginx config)
kubectl apply -f app-code-configmap.yaml

# Apply the Deployment manifest for the Nginx web apps
kubectl apply -f deployment.yaml

# Apply Services and GCPBackendPolicy manifest
kubectl apply -f services-backendpolicy.yaml

# Apply the Gateway, HTTPRoute and ReferenceGrant manifest
kubectl apply -f gateway-httproute-grants.yaml

# Verify resources have been created successfully
kubectl get pods -A
kubectl get services -A
kubectl get deployment -A
kubectl get gatewayclass -A
kubectl get gateway -A
kubectl get httproute -A
kubectl get gcpbackendpolicy -A
