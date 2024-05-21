#!/bin/bash

######################################################################################################
# ** About this script **
# This script can add one or multiple routes to a specified VPC route table in AWS for a given 
# destination CIDR block and destination.
######################################################################################################

# Set variables for the destination CIDR block, transit gateway ID, and table name prefix
destination_cidr='10.0.0.0/16'
transit_gateway_id='tgw-xxxxx'
table_prefix='workspaces'

# Retrieve a list of route tables from AWS EC2
route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[*].{RouteTableId:RouteTableId, Name:Tags[?Key==`Name`]|[0].Value}' --output json)

# Iterate through each route table
for table in $(echo "${route_tables}" | jq -c '.[]'); do
   table_id=$(echo "${table}" | jq -r '.RouteTableId')
   table_name=$(echo "${table}" | jq -r '.Name')

   # Check if the route table name contains the specified prefix
   if [[ "${table_name}" == *"${table_prefix}"* ]]; then
     echo "Adding route to table ${table_name} (${table_id})"

       # Add the route to the transit gateway
       echo  "Route added to ${table_name} (${table_id})"
       aws ec2 create-route --route-table-id "${table_id}" --destination-cidr-block ${destination_cidr} --transit-gateway-id ${transit_gateway_id}
   fi
done
