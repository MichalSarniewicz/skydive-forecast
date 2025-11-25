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

resource "docker_container" "postgres_user" {
  name  = "postgres-user"
  image = "postgres:15-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  env = [
    "POSTGRES_DB=userdb",
    "POSTGRES_USER=userservice",
    "POSTGRES_PASSWORD=userpass"
  ]

  ports {
    internal = 5432
    external = 15432
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U userservice -d userdb"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

resource "docker_container" "redis" {
  name  = "redis"
  image = "redis:7-alpine"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  ports {
    internal = 6379
    external = 16379
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 5
  }
}

resource "docker_container" "consul" {
  name  = "consul"
  image = "hashicorp/consul:1.20"
  
  networks_advanced {
    name = docker_network.skydive_network.name
  }

  command = ["agent", "-dev", "-ui", "-client=0.0.0.0"]

  ports {
    internal = 8500
    external = 8500
  }

  healthcheck {
    test     = ["CMD", "consul", "info"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}
