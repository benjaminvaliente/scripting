#!/bin/bash

# Variables
SECURITY_GROUP_ID="sg-0bdb89634ef61e0c8"
PORT=22
PROTOCOL="tcp"
DESCRIPTION="Clientes General"
IP_LIST=("134.42.96.2/32" "170.169.127.30/32" "170.169.130.1/32" "187.162.170.87/32" "187.167.186.60/32" "189.201.136.133/32" "189.204.69.154/32" "189.216.196.125/32" "189.216.198.125/32" "192.193.216.154/32" "193.104.63.58/32" "199.242.0.29/32" "199.242.6.29/32" "199.67.131.150/32" "199.67.138.41/32" "199.67.140.41/32" "200.16.40.155/32" "200.66.67.94/32" "200.66.71.106/32" "201.134.170.26/32" "201.161.42.34/32" "209.148.37.178/32" "38.124.171.77/32" "54.165.95.154/32" "148.243.176.50/32" "201.134.128.66/32" "189.216.199.200/32" "201.134.132.134/32" "201.134.170.15/32" "187.188.11.210/32" "192.100.169.50/32" "34.221.115.88/32" "189.203.131.143/32" "189.203.131.146/32" "187.189.84.186/32" "54.203.41.41/32" "200.13.117.15/32" "18.207.74.154/32" "201.149.58.93/32" "187.191.11.235/32" "187.189.173.206/32" "44.235.115.213/32" "52.88.69.224/32")

# Create the IpPermissions string
IP_PERMISSIONS="["

for IP in "${IP_LIST[@]}"
do
    IP_PERMISSIONS+="{\"IpProtocol\":\"$PROTOCOL\",\"FromPort\":$PORT,\"ToPort\":$PORT,\"IpRanges\":[{\"CidrIp\":\"$IP\",\"Description\":\"$DESCRIPTION\"}]},"
done

# Remove the trailing comma from the last entry and close the JSON array
IP_PERMISSIONS=${IP_PERMISSIONS::-1}
IP_PERMISSIONS+="]"

# Execute the AWS CLI command to add the rules
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --ip-permissions "$IP_PERMISSIONS"

echo "Added rules to allow SSH access for the specified IPs on port $PORT with description: '$DESCRIPTION'"