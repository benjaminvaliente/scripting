#!/bin/bash

######################################################################################################
# ** About this script **
# This bash script performs a series of operations to manage Azure Kubernetes Service (AKS) and 
# update Azure Private DNS records with the IP addresses of specific pods.
######################################################################################################

# Connect to AKS cluster
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin

# Converting to azurecli
kubelogin convert-kubeconfig -l azurecli

# Getting AKS nodes
kubectl get nodes

# Set kubectl namespace to current context
kubectl config set-context --current --namespace=$AKS_NAMESPACE

# Use `kubectl` to get the list of pods and filter them by name prefix
POD_NAMES=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "^${DNS_POD_NAME_PREFIX}")

# Loop through the filtered pod names to retrieve their IP addresses
POD_IP=()
for POD_NAME in $POD_NAMES; do
  IP=$(kubectl get pod "$POD_NAME" -o custom-columns="POD_IP:.status.podIP" --no-headers)
  if [ -n "$IP" ]; then
    POD_IP=("$IP")
  fi
done

# Get current IP address in A record if it exists, suppressing errors
OLD_IP=$(az network private-dns record-set a show --resource-group $DNS_RESOURCE_GROUP --zone-name $DNS_PRIVATE_ZONE_NAME --name $DNS_RECORDNAME | grep -o '"ipv4Address": "[^"]*' | awk -F': "' '{print $2}' 2>/dev/null)

if [ -z "$OLD_IP" ]; then
    # If the DNS record doesn't exist, create a new record
    echo "Record doesn't exist. Creating a new record with dummy IP..."
    TEMP_IP=172.20.0.1    
    # Create a new record with a dummy IP
    az network private-dns record-set a add-record --resource-group $DNS_RESOURCE_GROUP --zone-name $DNS_PRIVATE_ZONE_NAME --record-set-name $DNS_RECORDNAME --ipv4-address $TEMP_IP
    # Update TTL separately for the newly created record
    az network private-dns record-set a update --resource-group $DNS_RESOURCE_GROUP --zone-name $DNS_PRIVATE_ZONE_NAME --name $DNS_RECORDNAME --set ttl=10
    echo "New temporary DNS record created."
else
    echo "DNS record already exists with IP: $OLD_IP. Skipping DNS creation..."
fi

# Add A records to Azure Private DNS
echo "Adding A record for Pod IP: $POD_IP"
az network private-dns record-set a add-record --resource-group $DNS_RESOURCE_GROUP --record-set-name $DNS_RECORDNAME --zone-name $DNS_PRIVATE_ZONE_NAME  --ipv4-address $POD_IP

# Remove old A record from Azure Private DNS
echo "Removing old A record for Pod IP: $OLD_IP"
for ip in $OLD_IP; do
az network private-dns record-set a remove-record --resource-group $DNS_RESOURCE_GROUP --record-set-name $DNS_RECORDNAME --zone-name $DNS_PRIVATE_ZONE_NAME  --ipv4-address $ip
done

# Remove temporary A record from Azure Private DNS
echo "Removing old A record for Pod IP: $TEMP_IP"
for ip in $TEMP_IP; do
az network private-dns record-set a remove-record --resource-group $DNS_RESOURCE_GROUP --record-set-name $DNS_RECORDNAME --zone-name $DNS_PRIVATE_ZONE_NAME  --ipv4-address $ip
done