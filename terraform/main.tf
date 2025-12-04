terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "skydive_network" {
  name = "skydive-network"
}

# PostgreSQL for User Service
resource "docker_container" "postgres_user" {
  name  = "skydive-postgres-user"
  image = "postgres:15-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  env = [
    "POSTGRES_DB=skydive_forecast_user_db",
    "POSTGRES_USER=skydive_forecast_user",
    "POSTGRES_PASSWORD=pass"
  ]

  ports {
    internal = 5432
    external = 15432
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U skydive_forecast_user -d skydive_forecast_user_db"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# PostgreSQL for Analysis Service
resource "docker_container" "postgres_analysis" {
  name  = "skydive-postgres-analysis"
  image = "postgres:15-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  env = [
    "POSTGRES_DB=skydive_forecast_analysis_db",
    "POSTGRES_USER=skydive_forecast_analysis",
    "POSTGRES_PASSWORD=pass"
  ]

  ports {
    internal = 5432
    external = 15433
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U skydive_forecast_analysis -d skydive_forecast_analysis_db"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# PostgreSQL for Location Service
resource "docker_container" "postgres_location" {
  name  = "skydive-postgres-location"
  image = "postgres:15-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  env = [
    "POSTGRES_DB=skydive_forecast_location_db",
    "POSTGRES_USER=skydive_forecast_location",
    "POSTGRES_PASSWORD=pass"
  ]

  ports {
    internal = 5432
    external = 15434
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U skydive_forecast_location -d skydive_forecast_location_db"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Redis with password
resource "docker_container" "redis" {
  name  = "skydive-redis"
  image = "redis:7-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  command = ["redis-server", "--requirepass", "pass", "--appendonly", "yes"]

  ports {
    internal = 6379
    external = 16379
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "-a", "pass", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 5
  }
}

# Zookeeper for Kafka
resource "docker_container" "zookeeper" {
  name  = "skydive-zookeeper"
  image = "confluentinc/cp-zookeeper:7.5.0"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  env = [
    "ZOOKEEPER_CLIENT_PORT=2181",
    "ZOOKEEPER_TICK_TIME=2000"
  ]

  ports {
    internal = 2181
    external = 2181
  }
}

# Kafka
resource "docker_container" "kafka" {
  name  = "skydive-kafka"
  image = "confluentinc/cp-kafka:7.5.0"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  depends_on = [docker_container.zookeeper]

  env = [
    "KAFKA_BROKER_ID=1",
    "KAFKA_ZOOKEEPER_CONNECT=skydive-zookeeper:2181",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://skydive-kafka:9092,PLAINTEXT_HOST://localhost:19092",
    "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT",
    "KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT",
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1",
    "KAFKA_AUTO_CREATE_TOPICS_ENABLE=true"
  ]

  ports {
    internal = 9092
    external = 19092
  }

  healthcheck {
    test     = ["CMD", "kafka-broker-api-versions", "--bootstrap-server", "localhost:9092"]
    interval = "10s"
    timeout  = "10s"
    retries  = 5
  }
}

# Consul
resource "docker_container" "consul" {
  name  = "skydive-consul"
  image = "consul:1.15"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  command = ["agent", "-server", "-ui", "-bootstrap-expect=1", "-client=0.0.0.0"]

  ports {
    internal = 8500
    external = 8500
  }

  healthcheck {
    test     = ["CMD", "consul", "members"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}
