#!/bin/bash
# Update the OS
sudo yum update -y

# Install CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle","cpu_usage_iowait","cpu_usage_user","cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "EC2Syslog",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "EC2CloudInit",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOT

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s