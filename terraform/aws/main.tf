terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "skydive-vpc" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "skydive-private-${count.index + 1}" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 10}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "skydive-public-${count.index + 1}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "skydive-igw" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "skydive-nat" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "skydive-nat-eip" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "skydive-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "skydive-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb" {
  name   = "skydive-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "skydive-ecs-tasks-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "skydive-rds-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "skydive-db-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "user" {
  identifier             = "skydive-user-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "userdb"
  username               = "userservice"
  password               = var.db_password_user
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

resource "aws_db_instance" "analysis" {
  identifier             = "skydive-analysis-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "analysisdb"
  username               = "analysisservice"
  password               = var.db_password_analysis
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

resource "aws_db_instance" "location" {
  identifier             = "skydive-location-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "locationdb"
  username               = "locationservice"
  password               = var.db_password_location
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "skydive-redis-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "skydive-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.ecs_tasks.id]
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "skydive-kafka"
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
    storage_info {
      ebs_storage_info {
        volume_size = 10
      }
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = "skydive-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_lb" "main" {
  name               = "skydive-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "gateway" {
  name        = "skydive-gateway-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }
}

resource "aws_ecr_repository" "gateway" {
  name = "skydive-gateway"
}

resource "aws_ecr_repository" "user_service" {
  name = "skydive-user-service"
}

resource "aws_ecr_repository" "analysis_service" {
  name = "skydive-analysis-service"
}

resource "aws_ecr_repository" "location_service" {
  name = "skydive-location-service"
}

resource "aws_ecr_repository" "config_server" {
  name = "skydive-config-server"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "skydive-ecs-task-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "consul" {
  family                   = "skydive-consul"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name    = "consul"
    image   = "consul:1.15"
    command = ["agent", "-server", "-ui", "-bootstrap-expect=1", "-client=0.0.0.0"]
    portMappings = [
      { containerPort = 8500, protocol = "tcp" },
      { containerPort = 8600, protocol = "udp" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.consul.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "config_server" {
  family                   = "skydive-config-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name  = "config-server"
    image = "${aws_ecr_repository.config_server.repository_url}:latest"
    portMappings = [{ containerPort = 8888, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "git" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.config_server.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "user_service" {
  family                   = "skydive-user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name  = "user-service"
    image = "${aws_ecr_repository.user_service.repository_url}:latest"
    portMappings = [{ containerPort = 8081, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "prod,consul" },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.user.endpoint}/skydive_forecast_user_db" },
      { name = "SPRING_DATASOURCE_USERNAME", value = "skydive_forecast_user" },
      { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password_user },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_elasticache_cluster.redis.cache_nodes[0].address },
      { name = "SPRING_DATA_REDIS_PASSWORD", value = var.redis_password },
      { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = aws_msk_cluster.kafka.bootstrap_brokers },
      { name = "JWT_SECRET", value = var.jwt_secret }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.user_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "analysis_service" {
  family                   = "skydive-analysis-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name  = "analysis-service"
    image = "${aws_ecr_repository.analysis_service.repository_url}:latest"
    portMappings = [{ containerPort = 8082, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "prod,consul" },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.analysis.endpoint}/skydive_forecast_analysis_db" },
      { name = "SPRING_DATASOURCE_USERNAME", value = "skydive_forecast_analysis" },
      { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password_analysis },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_elasticache_cluster.redis.cache_nodes[0].address },
      { name = "SPRING_DATA_REDIS_PASSWORD", value = var.redis_password },
      { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = aws_msk_cluster.kafka.bootstrap_brokers },
      { name = "JWT_SECRET", value = var.jwt_secret }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.analysis_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "location_service" {
  family                   = "skydive-location-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name  = "location-service"
    image = "${aws_ecr_repository.location_service.repository_url}:latest"
    portMappings = [{ containerPort = 8083, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "prod,consul" },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.location.endpoint}/skydive_forecast_location_db" },
      { name = "SPRING_DATASOURCE_USERNAME", value = "skydive_forecast_location" },
      { name = "SPRING_DATASOURCE_PASSWORD", value = var.db_password_location },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_elasticache_cluster.redis.cache_nodes[0].address },
      { name = "SPRING_DATA_REDIS_PASSWORD", value = var.redis_password },
      { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = aws_msk_cluster.kafka.bootstrap_brokers },
      { name = "JWT_SECRET", value = var.jwt_secret }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.location_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "gateway" {
  family                   = "skydive-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([{
    name  = "gateway"
    image = "${aws_ecr_repository.gateway.repository_url}:latest"
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_elasticache_cluster.redis.cache_nodes[0].address },
      { name = "SPRING_DATA_REDIS_PASSWORD", value = var.redis_password }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.gateway.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "consul" {
  name            = "skydive-consul"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.consul.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "config_server" {
  name            = "skydive-config-server"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.config_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "user_service" {
  name            = "skydive-user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "analysis_service" {
  name            = "skydive-analysis-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analysis_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "location_service" {
  name            = "skydive-location-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.location_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "gateway" {
  name            = "skydive-gateway"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.gateway.arn
    container_name   = "gateway"
    container_port   = 8080
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/ecs/skydive-gateway"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/skydive-user-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "analysis_service" {
  name              = "/ecs/skydive-analysis-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "location_service" {
  name              = "/ecs/skydive-location-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "config_server" {
  name              = "/ecs/skydive-config-server"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "consul" {
  name              = "/ecs/skydive-consul"
  retention_in_days = 7
}

data "aws_availability_zones" "available" {
  state = "available"
}
