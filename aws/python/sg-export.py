######################################################################################################
# ** About this script **
# This Python script retrieves security groups' information like allowed ports, rules, etc, that
# are defined to all the EC2 instances in an specific region and writes it to a formated CSV file.
######################################################################################################

import boto3
import os
import csv

def write_to_csv(data, filename):
    """
    Write security group information to a CSV file.

    Parameters:
    data (list of dict): A list of dictionaries containing security group information.
    filename (str): The name of the CSV file to write the data to.
    """
    with open(filename, 'w', newline='') as csvfile:
        # Define the header fields for the CSV file
        fieldnames = ['SecurityGroupId', 'Description', 'FromPort', 'ToPort', 'Protocol', 'IPRange', 'AssociatedInstances', 'RuleDescription']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        # Write the header to the CSV file
        writer.writeheader()
        for row in data:
            # Process inbound rules
            for inbound_rule in row['InboundRules']:
                for ip_range in inbound_rule.get('IpRanges', []):
                    new_row = {
                        'SecurityGroupId': row['SecurityGroupId'],
                        'Description': row['Description'],
                        'FromPort': inbound_rule.get('FromPort', 'All'),
                        'ToPort': inbound_rule.get('ToPort', 'All'),
                        'Protocol': inbound_rule['IpProtocol'],
                        'IPRange': ip_range['CidrIp'],
                        'AssociatedInstances': ', '.join(instance['InstanceId'] for instance in row['AssociatedInstances']),
                        'RuleDescription': ip_range.get('Description', '')
                    }
                    # Write the row to the CSV file
                    writer.writerow(new_row)

            # Process outbound rules
            for outbound_rule in row['OutboundRules']:
                for ip_range in outbound_rule.get('IpRanges', []):
                    new_row = {
                        'SecurityGroupId': row['SecurityGroupId'],
                        'Description': row['Description'],
                        'FromPort': outbound_rule.get('FromPort', 'All'),
                        'ToPort': outbound_rule.get('ToPort', 'All'),
                        'Protocol': outbound_rule['IpProtocol'],
                        'IPRange': ip_range['CidrIp'],
                        'AssociatedInstances': ', '.join(instance['InstanceId'] for instance in row['AssociatedInstances']),
                        'RuleDescription': ip_range.get('Description', '')
                    }
                    # Write the row to the CSV file
                    writer.writerow(new_row)

def get_security_groups():
    """
    Retrieve security groups from AWS and write their details to a CSV file.
    """
    # AWS 'PROFILE' and 'REGION' environment variables should be defined previous to the script execution
    aws_profile = os.environ['PROFILE']  # AWS profile name
    aws_region = os.environ['REGION']  # AWS region name
    ec2 = boto3.Session(profile_name=aws_profile, region_name=aws_region).client('ec2')

    csv_data = []

    next_token = None
    while True:
        try:
            # Retrieve security groups using pagination
            response = ec2.describe_security_groups(NextToken=next_token) if next_token else ec2.describe_security_groups()
        except Exception as e:
            print(f"Error retrieving security groups: {e}")
            break  # Exit the loop if there's an error

        for group in response['SecurityGroups']:
            try:
                # Retrieve instances associated with the security group
                associated_instances = ec2.describe_instances(Filters=[{'Name': 'instance.group-id', 'Values': [group['GroupId']]}])
                security_group_info = {
                    'SecurityGroupId': group['GroupId'],
                    'Description': group['Description'],
                    'InboundRules': group['IpPermissions'],
                    'OutboundRules': group['IpPermissionsEgress'],
                    'AssociatedInstances': associated_instances['Reservations'][0]['Instances'] if associated_instances['Reservations'] else []
                }
                # Append security group info to the list
                csv_data.append(security_group_info)
            except Exception as e:
                print(f"Error processing security group {group['GroupId']}: {e}")

        next_token = response.get('NextToken')
        if not next_token:
            break

    # Write collected data to a CSV file
    write_to_csv(csv_data, 'security_groups_info.csv')

if __name__ == "__main__":
    get_security_groups()
