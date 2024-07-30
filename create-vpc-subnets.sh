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

# Set the Availability Zone for the private subnet
AZ_2A="us-west-2a"
AZ_2B="us-west-2b"

# Recommended private subnet IP range
SUBNET_2A_CIDR="XXX.XX.64.0/20" # Replace with your private subnet CIDR
SUBNET_2B_CIDR="XXX.XX.80.0/20" # Replace with your private subnet CIDR

# Create the private subnet
PRIVATE_SUBNET_2A_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_2A_CIDR \
    --availability-zone $AZ_2A \
    --query 'Subnet.SubnetId' \
    --output text)


PRIVATE_SUBNET_2B_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_2B_CIDR \
    --availability-zone $AZ_2B \
    --query 'Subnet.SubnetId' \   
    --output text)

# Add a name tag to the private subnet
aws ec2 create-tags \
    --resources $PRIVATE_SUBNET_2A_ID \
    --tags "Key=Name,Value=tm-lambda-private-subnet-2a"

aws ec2 create-tags \
    --resources $PRIVATE_SUBNET_2B_ID \
    --tags "Key=Name,Value=tm-lambda-private-subnet-2b"

# Disable auto-assign public IPv4 address on the private subnet
aws ec2 modify-subnet-attribute \
    --subnet-id $PRIVATE_SUBNET_2A_ID \
    --no-map-public-ip-on-launch

# Disable auto-assign public IPv4 address on the private subnet
aws ec2 modify-subnet-attribute \
    --subnet-id $PRIVATE_SUBNET_2B_ID \
    --no-map-public-ip-on-launch


echo "Private subnet 2A ID: $PRIVATE_SUBNET_ID"
echo "Private subnet 2B ID: $PRIVATE_SUBNET_ID"