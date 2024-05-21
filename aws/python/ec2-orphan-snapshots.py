######################################################################################################
# ** About this script **
# This script can compare the snapshots associated to EC2 instances volumes in an AWS account and 
# based on the snapshot information a list of orphan snapshots is created into a CSV file.
######################################################################################################

import boto3
import csv
import re

def get_account_info():
    # Create a Boto3 client for IAM
    iam_client = boto3.client('iam')
    
    # Retrieve account information
    account_info = iam_client.list_account_aliases()
    account_id = boto3.client('sts').get_caller_identity().get('Account')
    
    return account_id


def get_ec2_instances():
    # Create a Boto3 client for EC2
    ec2_client = boto3.client('ec2')
    
    # Retrieve all EC2 instances
    response = ec2_client.describe_instances()
    
    # Extract instance IDs
    instances = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instances.append(instance['InstanceId'])
   
    return instances

def get_snapshots():
    # Create a Boto3 client for EC2
    ec2_client = boto3.client('ec2')
    
    # Retrieve all snapshots
    response = ec2_client.describe_snapshots(OwnerIds=['self'])
    
    # Extract relevant information
    snapshots = response['Snapshots']
    
    return snapshots

def find_orphan_snapshots(ec2_instances, snapshots):
    orphan_snapshots = []
    pattern = r'Created by CreateImage\((.*?)\) for'

    for snapshot in snapshots:
        description = snapshot['Description']
        match = re.search(pattern, description)
        if match:
            instance_id = match.group(1)
            if instance_id not in ec2_instances:
                orphan_snapshots.append({'Snapshot': snapshot, 'InstanceId': instance_id})
        else:
            # Handle unexpected description format
            orphan_snapshots.append({'Snapshot': snapshot, 'InstanceId': 'Unknown'})
    
    return orphan_snapshots

def write_to_csv(account_id, orphan_snapshots, output_file):
    # Write orphaned snapshots to CSV file
    with open(output_file, mode='w', newline='') as csv_file:
        fieldnames = ['AccountId', 'SnapshotId', 'InstanceId', 'Description']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        
        writer.writeheader()
        for orphan_snapshot in orphan_snapshots:
            snapshot = orphan_snapshot['Snapshot']
            instance_id = orphan_snapshot['InstanceId']
            writer.writerow({
                'AccountId': account_id,
                'SnapshotId': snapshot['SnapshotId'],
                'InstanceId': instance_id,
                'Description': snapshot['Description']
            })

def main():
    account_id = get_account_info()
    ec2_instances = get_ec2_instances()
    snapshots = get_snapshots()    
    orphan_snapshots = find_orphan_snapshots(ec2_instances, snapshots)
    
    # Print orphaned snapshots
    if orphan_snapshots:
        print("Orphaned Snapshots:")
        for orphan_snapshot in orphan_snapshots:
            snapshot = orphan_snapshot['Snapshot']
            instance_id = orphan_snapshot['InstanceId']
            print(f"  Snapshot ID: {snapshot['SnapshotId']}, Instance ID: {instance_id}")
    else:
        print("No orphaned snapshots found.")
    
    # Write orphaned snapshots to CSV file
    output_file = 'orphan_snapshots.csv'
    write_to_csv(account_id, orphan_snapshots, output_file)
    print(f"Orphaned snapshots written to {output_file}")

if __name__ == "__main__":
    main()