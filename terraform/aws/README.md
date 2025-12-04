# Skydive Forecast - AWS Infrastructure with Terraform

This directory contains Terraform configuration for deploying Skydive Forecast to AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- An AWS account with permissions to create VPC, ECS, RDS, ElastiCache, MSK resources

## Architecture

```
AWS Cloud
├── VPC (10.0.0.0/16)
│   ├── Public Subnets (2x AZ)
│   │   ├── Application Load Balancer
│   │   ├── NAT Gateway
│   │   └── Internet Gateway
│   │
│   └── Private Subnets (2x AZ)
│       ├── ECS Fargate Cluster
│       │   ├── Gateway (2 tasks)
│       │   ├── User Service (2 tasks)
│       │   ├── Analysis Service (2 tasks)
│       │   ├── Location Service (2 tasks)
│       │   ├── Config Server (1 task)
│       │   └── Consul (1 task)
│       │
│       ├── RDS PostgreSQL
│       │   ├── User DB
│       │   ├── Analysis DB
│       │   └── Location DB
│       │
│       ├── ElastiCache Redis
│       └── MSK Kafka (2 brokers)
│
├── ECR Repositories (5 repos)
└── CloudWatch Log Groups
```

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/aws
terraform init
```

### 2. Configure Variables

Create a `terraform.tfvars` file:

```hcl
aws_region           = "eu-central-1"
db_password_user     = "your-secure-password-user"
db_password_analysis = "your-secure-password-analysis"
db_password_location = "your-secure-password-location"
redis_password       = "your-redis-password"
jwt_secret           = "your-jwt-secret-key-32-chars"
```

### 3. Plan and Apply

```bash
# Preview changes
terraform plan

# Apply infrastructure
terraform apply
```

### 4. Push Docker Images to ECR

After infrastructure is created:

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# Build and push images
docker build -t skydive-gateway ../skydive-forecast-gateway
docker tag skydive-gateway:latest $(terraform output -raw ecr_gateway_url):latest
docker push $(terraform output -raw ecr_gateway_url):latest

# Repeat for other services...
```

### 5. Access Application

```bash
# Get ALB DNS name
terraform output alb_dns_name
# Access at: http://<alb-dns-name>/swagger-ui.html
```

## Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `aws_region` | AWS region | No | `eu-central-1` |
| `db_password_user` | User DB password | Yes | - |
| `db_password_analysis` | Analysis DB password | Yes | - |
| `db_password_location` | Location DB password | Yes | - |
| `redis_password` | Redis password | No | `pass` |
| `jwt_secret` | JWT signing secret | No | `hK8nX2mP9qR5vT3wL7bE4jY6cA1dF8sZ` |

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Application Load Balancer DNS name |
| `ecr_gateway_url` | ECR repository URL for gateway |
| `ecr_user_service_url` | ECR repository URL for user-service |
| `ecr_analysis_service_url` | ECR repository URL for analysis-service |
| `ecr_location_service_url` | ECR repository URL for location-service |
| `ecr_config_server_url` | ECR repository URL for config-server |
| `rds_user_endpoint` | RDS endpoint for user database |
| `rds_analysis_endpoint` | RDS endpoint for analysis database |
| `rds_location_endpoint` | RDS endpoint for location database |
| `redis_endpoint` | ElastiCache Redis endpoint |
| `kafka_bootstrap_brokers` | MSK Kafka bootstrap brokers |

## Resources Created

### Networking
- VPC with DNS support
- 2 Public subnets (multi-AZ)
- 2 Private subnets (multi-AZ)
- Internet Gateway
- NAT Gateway with Elastic IP
- Route tables (public and private)

### Compute
- ECS Fargate cluster
- 7 ECS task definitions
- 7 ECS services (with auto-restart)
- Application Load Balancer
- Target group with health checks

### Databases
- 3x RDS PostgreSQL instances (db.t3.micro)
- 1x ElastiCache Redis cluster
- 1x MSK Kafka cluster (2 brokers)

### Security
- ALB security group (port 80)
- ECS tasks security group
- RDS security group (port 5432)
- IAM roles for ECS task execution

### Monitoring
- 6 CloudWatch Log Groups (7 days retention)

## Destroy Infrastructure

```bash
terraform destroy
```

> **Warning**: This will delete all resources including databases. Ensure backups are created.

## Production Considerations

### Security
- [ ] Enable HTTPS on ALB (add ACM certificate + listener on port 443)
- [ ] Use AWS Secrets Manager for sensitive variables
- [ ] Enable RDS encryption at rest
- [ ] Enable VPC flow logs
- [ ] Configure WAF on ALB

### High Availability
- [ ] Enable RDS Multi-AZ deployment
- [ ] Configure ECS service auto-scaling
- [ ] Use ElastiCache Redis replication

### Monitoring
- [ ] Set up CloudWatch alarms
- [ ] Configure SNS notifications
- [ ] Enable AWS X-Ray for tracing
- [ ] Consider using AWS Managed Grafana

### Backups
- [ ] Enable RDS automated backups
- [ ] Configure snapshot retention
- [ ] Set up cross-region replication

## Troubleshooting

### ECS tasks not starting
```bash
# Check ECS task logs
aws logs tail /ecs/skydive-gateway --follow

# Describe task failure
aws ecs describe-tasks --cluster skydive-cluster --tasks <task-arn>
```

### Cannot connect to RDS
- Verify security group allows traffic from ECS tasks
- Check RDS instance status in AWS Console
- Verify credentials in task definition

### Kafka connectivity issues
- MSK bootstrap brokers URL may take several minutes to become available
- Verify MSK cluster state is ACTIVE
- Check security group rules

## License

This infrastructure is part of the Skydive Forecast portfolio project.
