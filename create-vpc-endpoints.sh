#!/bin/bash
# Check if .env file exists
if [ -f .env ]; then
    echo "Sourcing .env file..."
    source .env
else
    echo "Error: .env file not found"
fi

# Check if AWS_PROFILE environment variable is set
if [ -z "$AWS_PROFILE" ]; then
    echo "Error: AWS_PROFILE environment variable is not set"
    exit 1
else
    echo "Using AWS profile: $AWS_PROFILE"
fi

required_vars=(
    AWS_REGION
    VPC_ID
)

# Loop through each required variable and check if it's set
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Variable $var is not set"
        exit 1
    fi
done

if [ ${VPC_SECURITY_GROUP_IDS[@]} -eq 0 ]; then
    echo "Error: VPC_SECURITY_GROUP_IDS is not set or empty"
    exit 1
fi

service_names=(
    "com.amazonaws.us-west-2.secretsmanager"
    "com.amazonaws.us-west-2.sqs"
)

echo "Creating VPC endpoints..."
echo "VPC ID: $VPC_ID"

for service_name in "${service_names[@]}"; do
    echo "Creating VPC endpoint for service: $service_name"
    # Create VPC endpoint
    aws ec2 create-vpc-endpoint \
        --vpc-id $VPC_ID \
        --vpc-endpoint-type Interface \
        --service-name $service_name 
done