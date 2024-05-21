#!/bin/bash

######################################################################################################
# ** About this script **
# This script allow the attachment of a single security group to multiple EC2 instances in the same
# AWS account.
######################################################################################################

# List of IP addresses of the instances you want to modify. This list can be defined in a separated file or in an environment variable depending on the script needs.
IP_ADDRESSES=("172.31.200.34"
"172.31.200.35"
"172.31.200.36"
"172.31.200.39"
"172.31.200.40"
"172.31.200.42"
"172.31.200.45"
"172.31.200.49"
"172.31.200.50"
"172.31.200.53"
"172.31.200.54"
"172.31.200.56"
"172.31.200.57"
"172.31.200.58"
"172.31.200.59"
"172.31.200.60"
"172.31.200.61"
"172.31.200.89"
"172.31.200.90")

# Security group ID you want to attach to the instances
SECURITY_GROUP_ID="sg-1234abcdf5678ef"

# Loop through each IP address
for IP_ADDRESS in "${IP_ADDRESSES[@]}"
do
    # Describe instances with the given IP address
    INSTANCE_ID=$(aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION --filters "Name=private-ip-address,Values=$IP_ADDRESS" --query "Reservations[].Instances[].InstanceId" --output text)

    # Check if INSTANCE_ID is not empty
    if [ -n "$INSTANCE_ID" ]; then
        echo "Adding security group $SECURITY_GROUP_ID to instance $INSTANCE_ID with IP address $IP_ADDRESS"

        # Get current security groups associated with the instance
        CURRENT_SECURITY_GROUPS=$(aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION --instance-id $INSTANCE_ID --query "Reservations[].Instances[].SecurityGroups[].GroupId" --output text)

        # Append the new security group to the list of current security groups
        NEW_SECURITY_GROUPS="$CURRENT_SECURITY_GROUPS $SECURITY_GROUP_ID"

        # Attach security groups to instance
        aws ec2 modify-instance-attribute --profile $AWS_PROFILE --region $AWS_REGION --instance-id $INSTANCE_ID --groups $NEW_SECURITY_GROUPS

        echo "Security group added successfully."
    else
        echo "No instances found with IP address $IP_ADDRESS"
    fi
done
