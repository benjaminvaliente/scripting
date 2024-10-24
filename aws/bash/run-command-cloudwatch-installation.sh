# Amazon Linux

# Get the OS name
os=$(awk -F= '$1 == "NAME" {gsub(/"/, "", $2); print $2}' /etc/os-release)

# Check the OS and execute the corresponding commands
if [ "$os" == "Amazon Linux AMI" ]; then
    echo "Detected Amazon Linux AMI. Downloading and installing CloudWatch Agent..."
    cd ~/
    sudo wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    sleep 5
    sudo rpm -U ./amazon-cloudwatch-agent.rpm
elif [ "$os" == "Amazon Linux" ]; then
    echo "Detected Amazon Linux. Installing CloudWatch Agent using yum..."
    sudo yum install amazon-cloudwatch-agent -y
elif [ "$os" == *"Ubuntu" || "$os" == *"Debian"* ]; then
    echo "Detected $os. Installing Cloudwtach Agent using dpkg..."
    cd ~/
    sudo wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
else
    echo "OS not recognized. Exiting..."
    exit 1
fi

# Common commands to configure CloudWatch Agent for all OS versions
echo "Configuring CloudWatch Agent..."

cat <<EOL > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
      "metrics_collection_interval": 60,
      "run_as_user": "root"
    },
    "metrics": {
      "append_dimensions": {
        "InstanceId": "\${aws:InstanceId}"
      },
      "metrics_collected": {
        "mem": {
          "measurement": [
            "mem_used_percent"
          ],
          "metrics_collection_interval": 60
        },
        "disk": {
          "measurement": [
            "disk_used_percent"
          ],
          "metrics_collection_interval": 60,
          "resources": [
            "*"
          ]
        },
        "swap": {
          "measurement": [
            "swap_used"
          ],
          "metrics_collection_interval": 60
        },
        "procstat": {
          "measurement": [
            "cpu_usage"
          ],
          "metrics_collection_interval": 60,
          "resources": [
            ".*"
          ]
        }
      }
    }
  }
EOL

sleep 5

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "CloudWatch Agent has been successfully configured and started."