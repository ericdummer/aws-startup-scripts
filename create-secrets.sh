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

# #create aws secrets
# PROD_SECRETE_NAME=tm-$TM_ENV_NAME-app-secret

# secret_json='{
#     "DB_USER":"lambda",
#     "DB_PASSWORD":"crIKbxmQpvtHiYNcNFTXCA",
#     "DB_HOST":"tm-prod-db-proxy.proxy-c7682m4y8951.us-west-2.rds.amazonaws.com",
#     "AWS_DEFAULT_REGION":"us-west-2",
#     "IRS_DOMAIN":"https://api.www4.irs.gov",
#     "IRS_CLIENT_ID":"d66660ac-7ba8-4ad5-85c6-2233ebb37c0c"
#     }'

# aws secretsmanager create-secret --name $PROD_SECRETE_NAME --secret-string "$secret_json"

LOCAL_SECRETE_NAME=tm-local-app-secret

secret_json='{
    "DB_USER":"postgres",
    "DB_PASSWORD":"postgrespassword",
    "DB_HOST":"docker.for.mac.localhost",
    "AWS_DEFAULT_REGION":"us-west-2",
    "IRS_DOMAIN":"https://api.www4.irs.gov",
    "IRS_CLIENT_ID":"d66660ac-7ba8-4ad5-85c6-2233ebb37c0c"
    }'


aws secretsmanager create-secret --name $LOCAL_SECRETE_NAME --secret-string "$secret_json"