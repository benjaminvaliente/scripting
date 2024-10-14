#!/bin/bash

# Define the prefix list name
PREFIX_LIST_NAME="pl-imperva"

# Define the IPs
IP_ADDRESSES=(
    "199.83.128.0/21"
    "198.143.32.0/19"
    "149.126.72.0/21"
    "103.28.248.0/22"
    "45.64.64.0/22"
    "185.11.124.0/22"
    "192.230.64.0/18"
    "107.154.0.0/16"
    "45.60.0.0/16"
    "45.223.0.0/16"
    "131.125.128.0/17"
)

# Create an empty array to hold the entries
ENTRIES=()

# Loop through each IP address and create the entry
for IP in "${IP_ADDRESSES[@]}"; do
    ENTRIES+=("Cidr=${IP},Description=${PREFIX_LIST_NAME}")
done

# Create the managed prefix list
aws ec2 create-managed-prefix-list \
    --address-family IPv4 \
    --max-entries ${#ENTRIES[@]} \
    --prefix-list-name "$PREFIX_LIST_NAME" \
    --entries "${ENTRIES[@]}"