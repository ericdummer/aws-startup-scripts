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

# Set the dry run flag (default is false)

# Check if the first argument is "--dry-run"
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=true
fi
echo "NO Dry run: $DRY_RUN | ${DRY_RUN:+--dry-run}"

required_vars=(
    AWS_REGION
    VPC_ID
    HASURA_IP_ADDRESS
)

# Set the security group name and description
DB_INSTANCE_IDENTIFIER=tm-$TM_ENV_NAME
DB_PROXY_SG_NAME=tm-$TM_ENV_NAME-db-proxy-sg
DB_PROXY_SG_DESRIPTION="TM db proxy securtiy group"
LAMBDA_SG_NAME=tm-$TM_ENV_NAME-lambda-sg
LAMBDA_SG_DESCRIPTION=tm-$TM_ENV_NAME-lambda-sg

VPN_SG_NAME=tm-$TM_ENV_NAME-db-vpn-sg
VPN_SG_DESCRIPTION="Security group for SSH access from the VPN IP"

HASURA_SG_NAME=tm-$TM_ENV_NAME-db-hasura-sg
HASURA_SG_DESCRIPTION="Allow PostgreSQL traffic from Hasura"

# Loop through each required variable and check if it's set
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Variable $var is not set"
        exit 1
    fi
done

# Create the security group
# aws ec2 create-security-group --group-name $HASURA_SG_NAME --description "$HASURA_SG_DESCRIPTION" ${DRY_RUN:+--dry-run}

# Get the security group ID
HASURA_SG_ID=$(aws ec2 describe-security-groups --filter "Name=group-name,Values=$HASURA_SG_NAME" --query 'SecurityGroups[0].GroupId' --output text ${DRY_RUN:+--dry-run}) 
echo "Security group ID: $HASURA_SG_ID"

# Add the rule to allow PostgreSQL traffic
# aws ec2 authorize-security-group-ingress --group-id $HASURA_SG_ID --ip-permissions '{"IpProtocol": "tcp", "FromPort": 5432, "ToPort": 5432, "IpRanges": [{"CidrIp": "'$HASURA_IP_ADDRESS/32'"}]}' ${DRY_RUN:+--dry-run}


aws rds modify-db-instance --db-instance-identifier $DB_INSTANCE_IDENTIFIER --vpc-security-group-ids $HASURA_SG_ID ${DRY_RUN:+--dry-run}
exit 1


echo ''
echo "Getting VPC CIDR..."
vpc_cidr=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].CidrBlock' --output text)
echo "VPC CIDR: $vpc_cidr"

echo ''
echo "Creating RDS Proxy Security Group..."
rds_proxy_sg_id=just-for-testing
rds_proxy_sg_id=$(aws ec2 create-security-group --group-name $DB_PROXY_SG_NAME --description "$DB_PROXY_SG_DESRIPTION" --vpc-id $VPC_ID --output text --query 'GroupId')


echo ''
echo "Creating ingress rule for VPC CIDR in RDS Proxy Security Group..."
aws ec2 authorize-security-group-ingress \
  --group-id $rds_proxy_sg_id \
  --protocol tcp \
  --port 5432 \
  --cidr $vpc_cidr

echo ''
echo "Creating Lambda Security Group..."
lambda_sg_id=just-for-testing
lambda_sg_id=$(aws ec2 create-security-group --group-name $LAMBDA_SG_NAME --description "$LAMBDA_SG_DESCRIPTION" --vpc-id $VPC_ID --output text --query 'GroupId')

echo ''
echo "Allowing outbound traffic from Lambda to RDS Proxy Security Group (PostgreSQL port)..."
aws ec2 authorize-security-group-egress \
  --group-id $lambda_sg_id \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0


echo ''
echo "Creating VPN security group..."
vpn_group_id=just-for-testing
vpn_group_id=$(aws ec2 create-security-group \
  --group-name $VPN_SG_NAME \
  --description "$VPN_SG_DESCRIPTION" \
  --vpc-id $VPC_ID \
  --output text 
  --query 'GroupId')

echo ''
echo "Authorizing postgres access (port 5432) from the VPN IP address..."
aws ec2 authorize-security-group-ingress \
  --group-id $vpn_group_id \
  --protocol tcp \
  --port 5432 \
  --cidr $VPN_IP_ADDERSS/32

echo ''
echo "Modifying RDS instance to use the new security group..."
aws rds modify-db-instance \
  --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
  --vpc-security-group-ids $vpn_group_id

echo "Security groups created:"
echo "RDS Proxy SG: $DB_PROXY_SG_NAME ($rds_proxy_sg_id)"
echo "Lambda SG: $LAMBDA_SG_NAME ($lambda_sg_id)"
echo "VPN SG: $VPN_SG_NAME ($vpn_group_id)"