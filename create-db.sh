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

# Check if DB_PASSWORD is set
if [ -n "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD is already set. Please unset it before running this script."
    exit 1
fi

echo "Generating random password..."
DB_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9!#$%&()*+,-.<=>?^_`{|}~' | head -c 12)

required_vars=(
    AWS_REGION
    VPC_ID
    DB_NAME
    DB_USER
    DB_PASSWORD
    DB_INSTANCE_CLASS
)

# Loop through each required variable and check if it's set
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Variable $var is not set"
        exit 1
    fi
done

DB_INSTANCE_IDENTIFIER=tm-$TM_ENV_NAME
echo "Createing db instance: $DB_INSTANCE_IDENTIFIER"

if [ ${#VPC_SECURITY_GROUP_IDS[@]} -eq 0 ]; then
    echo "Error: VPC_SECURITY_GROUP_IDS is not set or empty"
    exit 1
fi

# Check if each VPC_SECURITY_GROUP_ID is set
for sg_id in "${VPC_SECURITY_GROUP_IDS[@]}"; do
    if [[ -z "$sg_id" ]]; then
        echo "Error: VPC_SECURITY_GROUP_IDS contains an empty value"
        exit 1
    fi
done

echo "Creating RDS DB instance..."
# Create RDS DB instance

aws rds create-db-instance \
    --region $AWS_REGION \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine postgres \
    --db-name $DB_NAME \
    --allocated-storage 20 \
    --master-username $DB_USER \
    --master-user-password $DB_PASSWORD \
    --vpc-security-group-ids sg-0e13fa5bd7d4dfb5e sg-033862261b61a1432 sg-032e8ec25543b77ab sg-033862261b61a1432 \
    --auto-minor-version-upgrade \
    --storage-encrypted \
    --enable-performance-insights \
    --deletion-protection \
    --publicly-accessible

# Wait for the DB instance to be available
echo ''
echo "Waiting for DB instance to be available..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $AWS_REGION

# Get the RDS host (endpoint)
NEW_RDS_HOST=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text \
    --region "$AWS_REGION")

echo "EXPORTS:"
echo "export PGHOST=$NEW_RDS_HOST"
echo "export PGDATABASE=$DB_NAME"
echo "export PGUSER=$DB_USER"
echo "export PGPASSWORD=$DB_PASSWORD"

echo "Finished!"