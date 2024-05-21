#!/bin/bash

######################################################################################################
# ** About this script **
# This script automates the process of fetching AWS WorkSpaces information, extracting relevant 
# details, and saving them in a CSV file for easy analysis and reporting.
######################################################################################################

# Define the output CSV file name
output_file="workspaces-shared.csv"

# Get a list of WorkSpaces and format the output using jq
aws workspaces describe-workspaces --region $REGION --profile $PROFILE --output json > workspaces-shared.json

# Convert the JSON to CSV using jq and save to a CSV file
cat workspaces-shared.json | jq -r '.Workspaces[] | 
    [.WorkspaceId, .UserName, .WorkspaceProperties.ComputeTypeName, .WorkspaceProperties.RootVolumeSizeGib, .WorkspaceProperties.UserVolumeSizeGib, .State, .BundleId] | 
    @csv' > workspaces-shared.csv