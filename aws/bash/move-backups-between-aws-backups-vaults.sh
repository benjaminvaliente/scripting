#!/bin/bash

# This script copies all recovery points from one backup vault to another. It
# is useful when you want to migrate from one vault to another or consolidate
# backups from multiple accounts.
# Source: https://www.smartinary.com/blog/aws-backup-copy-recovery-points-between-vaults/

# Configuration (change these values)
SOURCE_VAULT="arn:aws:backup:us-east-1:224632425812:backup-vault:GENESIS_BACKUP_VIRGINIA"
TARGET_VAULT_ARN="arn:aws:backup:us-east-1:224632425812:backup-vault:GENESIS_UVG_1W"
IAM_ROLE_ARN="arn:aws:iam::224632425812:role/service-role/AWSBackupDefaultServiceRole"
# End of configuration

# List all recovery points in the source vault and store the ARN of each recovery point
RECOVERY_POINTS=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name "$SOURCE_VAULT" | jq -r '.RecoveryPoints[].RecoveryPointArn')

# Check if we got any recovery points
if [ -z "$RECOVERY_POINTS" ]; then
    echo "No recovery points found in the source vault."
    exit 1
fi

# Generate an idempotency token based on the current timestamp
TOKEN="copy-$(date +%s)"

# Copy each recovery point to the target vault
for RECOVERY_POINT_ARN in $RECOVERY_POINTS; do
    echo "Copying recovery point $RECOVERY_POINT_ARN to $TARGET_VAULT_ARN with token $TOKEN"
    SUCCESS=0
    while [ $SUCCESS -eq 0 ]; do
        RESULT=$(aws backup start-copy-job --recovery-point-arn "$RECOVERY_POINT_ARN" --source-backup-vault-name "$SOURCE_VAULT" --destination-backup-vault-arn "$TARGET_VAULT_ARN" --iam-role-arn "$IAM_ROLE_ARN" --idempotency-token "$TOKEN" 2>&1)
        if [ $? -eq 0 ]; then
            echo "Copy job initiated successfully!"
            SUCCESS=1
        else
            if echo "$RESULT" | grep -q 'LimitExceededException'; then
                echo "LimitExceededException: waiting 60 seconds before retrying"
                sleep 60
            elif echo "$RESULT" | grep -q 'ServiceUnavailableException'; then
                echo "ServiceUnavailableException: waiting 60 seconds before retrying"
                sleep 60
            elif echo "$RESULT" | grep -q 'NotFoundException'; then
                echo "NotFoundException: skipping this recovery point"
                SUCCESS=1
            else
                echo "Error: $RESULT"
                exit 1
            fi
        fi
    done
done

echo "All recovery points have been initiated for copying."