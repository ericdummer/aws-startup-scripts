# DEVOPS
Script for creating aws resources

## DB and DB Proxy 
1. Copy example.env to .env or create your own
1. Replace `<get from aws console>` with the appropriate values ... from the aws console
1. Call `./create-vpc-subnets.sh`
1. Add newly created subnet ids to `VPC_PRIVATE_SUBNET_IDS` in .env 
1. Call `./create-db.sh`
1. Call `./create-security-groups.sh`
1. Call `./create-lambda-user.sh`
1. Call `./create-hasura-user.sh`
1. Call `./create-readonly-user.sh your-user-name` for the prod environment. For others call`./create-personal-user.sh your-user-name`
1. Call `./create-db-proxy.sh`
1. Call `./create-vpc-endpoints.sh`