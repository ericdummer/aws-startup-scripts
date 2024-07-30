#!/bin/bash


# Validate the number of arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

# Define the environment parameter
ENVIRONMENT="$1"

# Load the environment file based on the parameter
case "$ENVIRONMENT" in
    prod)
        ENV_FILE="$HOME/.secrets/tm/.env-pg-prod-hasura"
        ;;
    staging)
        ENV_FILE="$HOME/.secrets/tm/.env-pg-stage-hasura"
        ;;
    dev)
        ENV_FILE="$HOME/.secrets/tm/.env-pg-stage-hasura"
        ;;
    local)
        ENV_FILE="$HOME/.secrets/tm/.env-pg-stage-hasura"
        ;;
    *)
        echo "Invalid environment. Supported environments: prod, dev, staging"
        exit 1
        ;;
esac

# Load the environment variables
if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
    echo "Loaded environment from $ENV_FILE"
else
    echo "Environment file $ENV_FILE not found."
    ls -l "$HOME/.secrets/tm"
    exit 1
fi


# Default environment variables for PostgreSQL connection
DB_USER=${PGUSER:-default_user}
DB_PASSWORD=${PGPASSWORD:-default_password}
DB_HOST=${PGHOST:-localhost}
DB_PORT=${PGPORT:-5432}
DB_NAME=${PGDATABASE:-default_db}

# Construct the PostgreSQL URL connection string
POSTGRESQL_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Export the connection string
# export POSTGRESQL_URL

# Print the connection string
echo -e "PostgreSQL URL:\n$POSTGRESQL_URL"

