#!/bin/bash

BUCKET_PREFIX='<bucket_name>'

# Fetch all S3 buckets with the prefix
buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '$BUCKET_PREFIX')].Name" --output text)


# Define the lifecycle policy JSON for non-current versions
lifecycle_policy=$(cat <<EOF
{
  "Rules": [
    {
      "ID": "move-to-glacier",
      "Filter": {
        "Prefix": ""
      },
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "GLACIER_IR"
        }
      ],
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "NoncurrentDays": 60,
          "StorageClass": "GLACIER"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 425
      },
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
EOF
)

# Apply the lifecycle policy to each bucket
for bucket in $buckets; do
  echo "Applying lifecycle policy to bucket: $bucket"
  
  # Apply the lifecycle policy
  aws s3api put-bucket-lifecycle-configuration --bucket "$bucket" --lifecycle-configuration "$lifecycle_policy"
  
  if [ $? -eq 0 ]; then
    echo "Successfully applied lifecycle policy to $bucket"
  else
    echo "Failed to apply lifecycle policy to $bucket"
  fi
done
