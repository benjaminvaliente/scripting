######################################################################################################
# ** About this script **
# This Python was desined to extract and export network usage metrics for all EC2 instances in an 
# AWS account over the past month.
######################################################################################################

import boto3
import csv
import os
from datetime import datetime, timedelta

# Initialize Boto3 EC2 and CloudWatch clients with profile. 
# AWS 'PROFILE' and 'REGION' environment variables should be defined previous to the script execution
session = boto3.Session(profile_name=os.environ['PROFILE'], region_name=os.environ['REGION'])
ec2_client = session.client('ec2')
cloudwatch_client = session.client('cloudwatch')

# Conversion factors
BYTE_TO_MIB = 1 / (1024 * 1024)

# Get current date
end_time = datetime.utcnow()

# Calculate start time (1 month ago)
start_time = end_time - timedelta(days=30)

# Create CSV file and write header
csv_file = open('ec2_network_metrics.csv', 'w', newline='')
csv_writer = csv.writer(csv_file)
csv_writer.writerow(['Instance ID', 'Network In (MiB)', 'Network Out (MiB)'])

# Initialize NextToken
next_token = None

while True:
    # Describe instances with NextToken
    if next_token:
        instances_response = ec2_client.describe_instances(NextToken=next_token)
    else:
        instances_response = ec2_client.describe_instances()

    # Paginate through instances
    for reservation in instances_response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            total_network_in = 0
            total_network_out = 0

            # Get network in metrics
            network_in_metrics = cloudwatch_client.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='NetworkIn',
                Dimensions=[
                    {'Name': 'InstanceId', 'Value': instance_id}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=86400,  # 1 day
                Statistics=['Sum']
            )

            # Get network out metrics
            network_out_metrics = cloudwatch_client.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='NetworkOut',
                Dimensions=[
                    {'Name': 'InstanceId', 'Value': instance_id}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=86400,  # 1 day
                Statistics=['Sum']
            )

            # Sum up network in metrics
            for data_point in network_in_metrics['Datapoints']:
                total_network_in += data_point['Sum']

            # Sum up network out metrics
            for data_point in network_out_metrics['Datapoints']:
                total_network_out += data_point['Sum']

            # Convert to MiB
            total_network_in_mib = total_network_in * BYTE_TO_MIB
            total_network_out_mib = total_network_out * BYTE_TO_MIB

            # Write metrics to CSV
            csv_writer.writerow([instance_id, total_network_in_mib, total_network_out_mib])

    # Check if there are more pages
    next_token = instances_response.get('NextToken')
    if not next_token:
        break

# Close CSV file
csv_file.close()

print("Metrics exported to ec2_network_metrics.csv")
