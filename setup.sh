#!/bin/bash

set -euo pipefail

# Create namespaces
for ns in app1 app2 gateway; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

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

# Create placeholder IAP secrets (REPLACE client_secret manually later)
for ns in app1 app2; do
  kubectl create secret generic iap-oauth-secret \
    --from-literal=client_secret='REPLACE_WITH_REAL_CLIENT_SECRET' \
    -n "$ns"
  echo "[✓] Created iap-oauth-secret in namespace $ns"
done
