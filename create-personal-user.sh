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

if [[ -z "$1" ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi
new_user="$1"

# don't do it if it is prod
# Check if TM_ENV_NAME contains 'prod' (case insensitive)
TM_ENV_NAME_LOWER=$(echo "$TM_ENV_NAME" | tr '[:upper:]' '[:lower:]')
if [[ "$TM_ENV_NAME_LOWER" == *prod* ]]; then
    echo "WARNING: you cannot create a personal user on the production environment."
    exit 1
fi

# Define the DB instance identifier

DB_INSTANCE_IDENTIFIER=tm-$TM_ENV_NAME

# Use the AWS CLI to describe the DB instance and extract the host name
export PGHOST=$(aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" --query "DBInstances[0].Endpoint.Address" --output text)
# PGHOST="uncomment line above"
export PGDATABASE=$DB_NAME
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD

echo "DB host name: $PGHOST"

if [[ -z "$PGHOST" || -z "$PGUSER" || -z "$PGPASSWORD" ]]; then
    echo "Error: PG environment variables not set"
    echo "PGHOST=$PGHOST"
    echo "PGUSER=$PGUSER"

    exit 1
fi

# Generate URL-safe password 
password_length=16
password=$(openssl rand -base64 $password_length | tr -cd 'A-Za-z0-9._-' ) 


# Set default database to sw2 - will change when out of POC
DB="${PGDATABASE}"
schema='public'

echo "psql $DB -c \"CREATE USER ${new_user} WITH LOGIN PASSWORD '$password'\"";
echo "psql $DB -c \"GRANT CONNECT ON DATABASE $DB TO ${new_user}\"";
echo "psql $DB -c \"GRANT USAGE ON SCHEMA $schema TO ${new_user}\"";
echo "psql $DB -c \"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $schema TO ${new_user}\""; 
echo "psql $DB -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${new_user}\""; 

psql $DB -c "CREATE USER ${new_user} WITH LOGIN PASSWORD '$password'"; 
psql $DB -c "GRANT CONNECT ON DATABASE $DB TO ${new_user}";
psql $DB -c "GRANT USAGE ON SCHEMA $schema TO ${new_user}";
psql $DB -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $schema TO ${new_user}"; 
psql $DB -c "ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${new_user}"; 

echo "EXPORTS:"
echo "export PGHOST=$PGHOST"
echo "export PGDATABASE=$PGDATABASE"
echo "export PGUSER=$new_user"
echo "export PGPASSWORD=$password"