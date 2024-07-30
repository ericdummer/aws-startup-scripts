#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <password> of the lambda user created by ./create-lambda-user.sh"
    exit 1
fi

# Retrieve the password from the first argument
password="$1"

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
    DB_INSTANCE_IDENTIFIER
    DB_NAME
    DB_INSTANCE_CLASS
)

DB_INSTANCE_IDENTIFIER=tm-$TM_ENV_NAME
DB_PROXY_NAME=tm-$TM_ENV_NAME-db-proxy
DB_PROXY_TARGET_GROUP_NAME=tm-$TM_ENV_NAME-db-proxy-target-group
DB_PROXY_SECURITY_GROUP_NAME=tm-$TM_ENV_NAME-db-proxy-sg
DB_PROXY_SECRET_NAME=tm-$TM_ENV_NAME-db-proxy-secret
LAMBDA_SECURITY_GROUP_NAME=tm-$TM_ENV_NAME-lambda-sg

# Generate a random secure password
DB_PROXY_USERNAME="lambda"
DB_PROXY_PASSWORD=$password

# Loop through each required variable and check if it's set
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Variable $var is not set"
        exit 1
    fi
done

if [ ${#VPC_PRIVATE_SUBNET_IDS[@]} -eq 0 ]; then
    echo "Error: VPC_PRIVATE_SUBNET_IDS is not set or empty"
    exit 1
fi

# Check if each VPC_SECURITY_GROUP_ID is set
for sg_id in "${VPC_PRIVATE_SUBNET_IDS[@]}"; do
    if [[ -z "$sg_id" ]]; then
        echo "Error: VPC_PRIVATE_SUBNET_IDS contains an empty value"
        exit 1
    fi
done

# Create AWS Secrets Manager secret for DB Proxy
echo ''
echo "DB_PROXY_USERNAME: $DB_PROXY_USERNAME"
echo "DB_PROXY_PASSWORD: $DB_PROXY_PASSWORD"

# echo "VPC_PRIVATE_SUBNET_IDS: ${VPC_PRIVATE_SUBNET_IDS[@]}"
# secret_string="{\"username\": \"$DB_PROXY_USERNAME\",\"password\":\"$DB_PROXY_PASSWORD\"}"
# aws secretsmanager create-secret \
#     --name $DB_PROXY_SECRET_NAME \ 
#     --secret-string "$secret_json"

# Get the ARN of the secret by its name
# db_proxy_secret_arn=arn:aws:secretsmanager:us-west-2:533267356524:secret:tm-prod-db-proxy-secret-8nejzP
# db_proxy_secret_arn=$(aws secretsmanager describe-secret --secret-id "$DB_PROXY_SECRET_NAME" --secret-string "$secret_string"--query ARN --output text)

# Print the ARN
echo -e "db_proxy_secret_arn: $DB_PROXY_SECRET_ARN"

# # Create IAM role for DB Proxy
# # Define variables
# ROLE_NAME=tm-$TM_ENV_NAME-db-proxy-for-lambdas
# ROLE_DESCRIPTION="Role for PROD DB Proxy"
# echo ''
# echo "ROLE_NAME: $ROLE_NAME"
# echo "ROLE_DESCRIPTION: $ROLE_DESCRIPTION"

# TRUST_RELATIONSHIP_POLICY='{
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "rds.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }'
# # # Create IAM role with trust relationship
# aws iam create-role --role-name $ROLE_NAME --description "$ROLE_DESCRIPTION" --assume-role-policy-document "$TRUST_RELATIONSHIP_POLICY"

# if [ $? -ne 0 ]; then
#     echo "Error: Failed to create IAM role"
#     exit 1
# fi
# # Attach the necessary policies
# aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document "$TRUST_RELATIONSHIP_POLICY"
# aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess
# aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonRDSDataFullAccess

# # Create IAM policy document granting access to the secret
# READ_SECRET_POLICY_DOCUMENT='{
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": "secretsmanager:GetSecretValue",
#             "Resource": "'"$db_proxy_secret_arn"'"
#         }
#     ]
# }'

# # Create IAM policy
# READ_SECRET_POLICY_NAME=tm-$TM_ENV_NAME-secret-access-policy
# aws iam create-policy \
#     --policy-name "$READ_SECRET_POLICY_NAME" \
#     --policy-document "$READ_SECRET_POLICY_DOCUMENT"

# db_proxy_policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='$READ_SECRET_POLICY_NAME'].Arn" --output text)
# db_proxy_policy_arn=arn:aws:iam::533267356524:policy/secret-access-policy
# aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $db_proxy_policy_arn

# get the ARN of the role
# db_proxy_role_arn=arn:aws:iam::533267356524:role/tm-prod-db-proxy-for-lambdas
# db_proxy_role_arn=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
# echo "db_proxy_role_arn: $db_proxy_role_arn"


# aws rds create-db-proxy \
#     --db-proxy-name $DB_PROXY_NAME \
#     --engine-family "POSTGRESQL" \
#     --auth "SecretArn=$db_proxy_secret_arn" \
#     --role-arn $db_proxy_role_arn \
#     --vpc-security-group-ids sg-0ccf7b9eb158f69cb \
#     $(printf -- "--vpc-subnet-ids %s " "${VPC_PRIVATE_SUBNET_IDS[@]}")

aws rds register-db-proxy-targets \
  --db-proxy-name $DB_PROXY_NAME  \
  --target-group-name default \
  --db-instance-identifiers $DB_INSTANCE_IDENTIFIER



  call modify for percentage
