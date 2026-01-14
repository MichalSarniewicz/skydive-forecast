# Skydive Forecast

[![Java](https://img.shields.io/badge/Java-21-green?logo=openjdk)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.6-brightgreen?logo=springboot)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2025.0.0-brightgreen)](https://spring.io/projects/spring-cloud)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
## Overview

A microservices application that analyzes weather data across multiple dropzones and uses AI to recommend optimal skydiving locations. Built with Spring Boot, Kafka event-driven architecture, distributed tracing, and complete CI/CD pipelines. Includes Docker Compose for local development and deployment configurations for Kubernetes and AWS.

### Status: **In Development**

## Features

- **Weather Analysis**: Comprehensive analysis of weather parameters (wind speed/direction, temperature, precipitation, cloud coverage, visibility) with scoring system, risk assessment, cross-dropzone comparisons, and automated report generation.
- **AI-Powered Recommendations**: OpenAI integration for natural language summaries and intelligent dropzone recommendations based on current weather conditions.
- **Microservices Architecture**: Dedicated services for Users, Analysis, Locations, and Gateway.
- **Security**: JWT-based authentication with Role-Based Access Control (RBAC).
- **Event-Driven**: Asynchronous communication using Apache Kafka.
- **Service Discovery**: Dynamic service registration via Consul.
- **Configuration Management**: Centralized configuration with Spring Cloud Config Server. External configuration repository for environment-specific settings.
- **Observability**: Monitoring with Grafana, Prometheus, Loki, Tempo, and OpenTelemetry.
- **Production Ready**: Kubernetes (Helm) and AWS (Terraform) deployment configurations.
- **CI/CD**: Automated pipelines with Testcontainers testing, security scanning, Docker builds, and registry deployment via GitHub Actions.
- **User Management**: Full user lifecycle (registration, authentication, profile updates, password management, activation/deactivation) with flexible RBAC for fine-grained access control.
## Architecture

The system follows a microservices architecture with a clear separation of concerns:

```mermaid
graph TB
    Client[Client]
    
    subgraph Discovery["Service Discovery"]
        Consul[Consul :8500]
        ConfigServer[Config Server :8888]
    end
    
    Gateway[API Gateway :8080]
    
    subgraph Services["Microservices"]
        User[User Service :8081]
        Analysis[Analysis Service :8082]
        Location[Location Service :8083]
    end
    
    subgraph Databases["Databases"]
        UserDB[(PostgreSQL<br/>User DB)]
        AnalysisDB[(PostgreSQL<br/>Analysis DB)]
        LocationDB[(PostgreSQL<br/>Location DB)]
    end
    
    subgraph Infrastructure["Infrastructure"]
        Redis[(Redis Cache)]
        Kafka[Kafka Broker]
    end
    
    subgraph Observability["Observability"]
        OTel[OTel Collector]
        Tempo[Tempo]
        Prometheus[Prometheus]
        Loki[Loki]
        Grafana[Grafana]
    end
    
    Client -->|HTTP/REST| Gateway
    Gateway -.->|Service Discovery| Consul
    Services -.->|Register| Consul
    Services -.->|Config| ConfigServer
    
    Gateway -->|JWT Auth| User
    Gateway -->|Route| Analysis
    Gateway -->|Route| Location
    
    User -->|JPA| UserDB
    Analysis -->|JPA| AnalysisDB
    Location -->|JPA| LocationDB
    
    User -->|Cache| Redis
    Analysis -->|Cache| Redis
    Location -->|Cache| Redis
    
    Analysis -->|Events| Kafka
    User -->|Events| Kafka
    Location -->|Events| Kafka
    
    Services -->|Traces/Metrics/Logs| OTel
    Gateway -->|Traces/Metrics/Logs| OTel
    OTel -->|Traces| Tempo
    OTel -->|Metrics| Prometheus
    OTel -->|Logs| Loki
    Tempo --> Grafana
    Prometheus --> Grafana
    Loki --> Grafana
```

### Service Responsibilities

#### Core Services

- **API Gateway** (Port 8080): Central entry point, JWT validation, request routing, rate limiting, API documentation
  aggregation
- **User Service** (Port 8081): Authentication (JWT), authorization (RBAC), user management, role/permission management
- **Analysis Service** (Port 8082): Weather data analysis, AI-powered forecasts (OpenAI), async report generation via
  Kafka
- **Location Service** (Port 8083): Dropzone CRUD operations, geographical queries, location data management

#### Infrastructure

- **Consul** (Port 8500): Service discovery, health checking, dynamic service registry
- **Config Server** (Port 8888): Centralized configuration management, externalized properties
- **PostgreSQL** (3 instances): Database per service pattern, data isolation
- **Redis** (Port 16379): Distributed caching, session storage, performance optimization
- **Kafka** (Port 19092): Event streaming, async communication, event-driven architecture

#### Observability (Grafana Stack)

- **OpenTelemetry Collector**: Unified telemetry collection (traces, metrics, logs)
- **Tempo** (Port 3200): Distributed tracing backend, integrated with Grafana
- **Prometheus** (Port 19090): Metrics collection and storage
- **Loki** (Port 13100): Log aggregation and querying
- **Grafana** (Port 3000): Unified observability UI (traces, metrics, logs)
- **Kafka UI** (Port 19000): Kafka monitoring, topic/consumer management

## Technology Stack

### Core Technologies

- **Java 21** - Modern Java features and performance
- **Spring Boot 3.5.6** - Microservices framework
- **Spring Cloud Gateway** - API gateway and routing
- **Spring Security** - JWT-based authentication
- **Spring Data JPA** - Database access with Hibernate
- **PostgreSQL 15** - Relational database (separate instance per service)
- **Redis 7** - Caching and session management
- **Apache Kafka** - Event streaming and asynchronous messaging
- **Monitoring**: Actuator, OpenTelemetry, Prometheus, Grafana, Loki, Tempo
- **Liquibase** - Database schema versioning
- **Docker & Docker Compose** - Containerization and local orchestration
- **Kubernetes & Helm** - Production deployment and orchestration

### Additional Tools

- **Spring AI with OpenAI** - AI-powered forecast recommendations
- **OpenTelemetry** - Unified observability (traces, metrics, logs)
- **Resilience4j** - Circuit breaker pattern for fault tolerance
- **MapStruct** - DTO and entity mapping
- **Lombok** - Boilerplate reduction
- **SpringDoc OpenAPI (Swagger)** - Interactive API documentation
- **Testcontainers** - Integration testing with PostgreSQL and Kafka
- **JUnit 5 & Mockito** - Unit testing
- **JaCoCo** - Code coverage (70% minimum)
- **WireMock & MockWebServer** - External service mocking

### Architecture Patterns

- **Hexagonal Architecture** (Ports and Adapters)
- **Event-Driven Architecture** (Kafka)
- **API Gateway Pattern**
- **Circuit Breaker Pattern**

## Prerequisites

- **Linux** / **macOS** / **Windows** (WSL or Git Bash)
- **Docker**  installed
- **Git** for cloning repositories
- **Java 21** (if running services locally without Docker)
- **Maven 3.x** (if building locally)
- **Make** (optional, for simplified commands)

## Makefile Commands

A `Makefile` is included for simplified project management:

| Command       | Description                            |
|---------------|----------------------------------------|
| `make start`  | Start all services                     |
| `make stop`   | Stop all services                      |
| `make logs`   | Follow logs of all services            |
| `make test`   | Run tests for all services             |
| `make build`  | Build all Docker images                |
| `make status` | Show status of containers              |
| `make clean`  | Stop and remove containers and volumes |

Run `make help` to see all available commands.

## Quick Start

### 1. Clone All Repositories

Run the setup script to clone all microservice repositories:

```bash
chmod +x setup.sh
./setup.sh
```

This will clone:

- `skydive-forecast-gateway`
- `skydive-forecast-user-service`
- `skydive-forecast-analysis-service`
- `skydive-forecast-location-service`
- `skydive-forecast-config-server`
- `skydive-forecast-svc-config`

### 2. Start All Services

Build and start all services with make:

```bash
make start
```

or using `docker-compose` directly:

```bash
docker-compose up --build
```

This command will:

- Build Docker images for all microservices
- Start infrastructure (PostgreSQL, Redis, Kafka, Consul)
- Start Config Server with externalized configurations
- Start all microservices with service discovery
- Start API Gateway
- Start observability stack (OTel, Tempo, Prometheus, Grafana, Loki)
- Run Liquibase migrations and seed test data

**First startup may take 2-3 minutes** as services initialize, register with Consul, and run database migrations.

Reference for checking container status:

![Docker Compose Status](docs/screenshots/docker-compose.png)
*Docker Compose stack showing 21 active containers. Note: 3 Liquibase containers will exit gracefully (Exit 0) after
database migrations complete.*

### 3. Verify Services

Check that all services are running:

```bash
docker-compose ps
```

All services should show status as "healthy".

### 4. Access the Application

- **API Gateway**: http://localhost:8080
- **Consul UI**: http://localhost:8500 (Service Discovery Dashboard)
- **Kafka UI**: http://localhost:19000 (Topics, Messages, Consumer Groups)
- **Swagger UI** (Aggregated): http://localhost:8080/swagger-ui.html
- **OpenAPI Docs**: http://localhost:8080/v3/api-docs

Individual service documentation:

- User Service: http://localhost:8081/swagger-ui.html
- Analysis Service: http://localhost:8082/swagger-ui.html
- Location Service: http://localhost:8083/swagger-ui.html

### 5. Test with Postman

For API testing, import the complete Postman collection:

1. Open Postman
2. Import files from `postman/` directory:
    - `Skydive-Forecast-API.postman_collection.json` (39 endpoints)
    - `Skydive-Forecast-Local.postman_environment.json` (environment variables)
3. Select "Skydive Forecast - Local" environment
4. Run `Authentication > Login (Admin)` to get JWT token (auto-saved)
5. Test any endpoint

## Monitoring & Observability

The project includes a comprehensive observability stack accessible via Grafana.

### Dashboards

![Grafana Dashboards](docs/screenshots/grafana-dashboards.png)
*Grafana Dashboards*

![Report Generation Metrics](docs/screenshots/grafana-dashboard-example.png)
*Example dasboard: System health*

### Distributed Tracing (Tempo)

![Tempo Traces](docs/screenshots/tempo-traces.png)
*Distributed tracing visualizing request flow across microservices*

### Kafka Monitoring

![Kafka UI](docs/screenshots/kafka-ui.png)
*Kafka UI for topic and consumer group management*

### Service Discovery (Consul)
![Service Discovery](docs/screenshots/consul-ui-services.png)
*Consul UI showing registered microservices*

## API Documentation

### Postman Collection

**Quick Start**: Import the complete Postman collection from `postman/` directory for instant API testing.

- **Collection**: `postman/Skydive-Forecast-API.postman_collection.json`
- **Environment**: `postman/Skydive-Forecast-Local.postman_environment.json`
- **Total Endpoints**: 39 (Authentication, Users, Roles, Permissions, Dropzones, Weather Reports)

![Postman Collection](docs/screenshots/postman.png)

### Aggregated Swagger

**Interactive API Documentation**: The API Gateway aggregates OpenAPI documentation from all microservices into a
unified Swagger UI.

- **Aggregated Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **OpenAPI Specification**: `http://localhost:8080/v3/api-docs`
- **Total Endpoints**: 39 (Authentication, Users, Roles, Permissions, Dropzones, Weather Reports)

![Swagger Collection](docs/screenshots/swagger.png)

### Main Endpoints

#### Authentication (`/api/users/**`)

- `POST /api/users/auth/token` - Generate JWT token (login)
- `POST /api/users/auth/refresh` - Refresh JWT token

#### User Management (`/api/users/**`)

- `GET /api/users` - Get all users (requires `USER_VIEW` permission)
- `POST /api/users` - Create new user (requires `USER_CREATE` permission)
- `PUT /api/users/{user-id}` - Update user (requires `USER_EDIT` permission)
- `PATCH /api/users/{user-id}/status` - Activate/deactivate user (requires `USER_STATUS_UPDATE` permission)
- `PATCH /api/users/me/password` - Change password (requires `USER_PASSWORD_CHANGE` permission)

#### Role & Permission Management (`/api/users/**`)

- `GET /api/users/roles` - Get all roles
- `POST /api/users/roles?role-name={name}` - Create new role
- `DELETE /api/users/roles/{role-id}` - Delete role
- `GET /api/users/permissions` - Get all permissions
- `POST /api/users/permissions` - Create permission
- `GET /api/users/role-permissions/role/{role-id}` - Get permissions by role
- `POST /api/users/role-permissions` - Assign permission to role
- `GET /api/users/user-roles/user/{user-id}` - Get roles for user
- `POST /api/users/user-roles` - Assign role to user

#### Location Management (`/api/locations/**`)

- `GET /api/locations/dropzones` - List all dropzones (requires `DROPZONE_VIEW` permission)
- `POST /api/locations/dropzones` - Create dropzone (requires `DROPZONE_CREATE` permission)
- `GET /api/locations/dropzones/{id}` - Get dropzone details (requires `DROPZONE_VIEW` permission)
- `GET /api/locations/dropzones/city/{city}` - Find dropzones by city (requires `DROPZONE_VIEW` permission)
- `PUT /api/locations/dropzones/{id}` - Update dropzone (requires `DROPZONE_UPDATE` permission)
- `DELETE /api/locations/dropzones/{id}` - Delete dropzone (requires `DROPZONE_DELETE` permission)

#### Weather Analysis (`/api/analyses/**`)

- `POST /api/analyses/reports/request` - Request weather report generation (async)
- `GET /api/analyses/reports/{reportId}` - Get weather report by ID
- `GET /api/analyses/reports` - List all user reports
- `GET /api/analyses/reports/latest` - Get latest user report

## Project Structure

This project uses a **multi-repository** approach where each microservice is maintained in its own Git repository:

```
Parent Directory/
├── skydive-forecast/                  # Main orchestration repository
│   ├── docker-compose.yml            # Docker Compose configuration
│   ├── setup.sh                      # Repository setup script
│   ├── monitoring/                   # Monitoring configurations
│   └── README.md                     # This file
│
├── skydive-forecast-gateway/          # API Gateway repository (Port 8080)
├── skydive-forecast-user-service/     # User Service repository (Port 8081)
├── skydive-forecast-analysis-service/ # Analysis Service repository (Port 8082)
├── skydive-forecast-location-service/ # Location Service repository (Port 8083)
├── skydive-forecast-config-server/    # Config Server repository (Port 8888)
└── skydive-forecast-svc-config/       # Configuration repository (Git-based configs)
```

Each microservice follows **Hexagonal Architecture**:

```
service/
├── src/main/java/com/skydiveforecast/
│   ├── application/service/     # Business logic (Use Cases)
│   ├── domain/                  # Domain models and ports
│   └── infrastructure/          # Adapters and configurations
│       ├── adapter/            # REST controllers, DTOs
│       ├── persistence/        # JPA repositories
│       ├── kafka/              # Kafka consumers/producers
│       └── security/           # JWT authentication
└── src/main/resources/
    └── db/changelog/           # Liquibase migrations
```

## Security & Authentication

### JWT-Based Authentication

- **Token Generation**: User Service issues JWT tokens upon successful login
- **Token Validation**: All services validate JWT tokens using shared secret
- **Token Refresh**: Refresh tokens for extended sessions
- **Stateless**: No server-side session storage

### Authorization (RBAC)

- **Role-Based Access Control**: Users assigned to roles (ADMIN, USER)
- **Permission-Based**: Fine-grained permissions (USER_VIEW, USER_CREATE, DROPZONE_VIEW, etc.)
- **Dynamic Assignment**: Roles and permissions managed via API
- **Gateway Enforcement**: JWT validation at API Gateway level

### Authentication Flow

```
1. POST /api/users/auth/token {email, password}
2. User Service validates credentials
3. Returns JWT token + refresh token
4. Client includes token in Authorization header: "Bearer {token}"
5. Gateway validates JWT and routes to services
6. Services verify token and check permissions
```

## Test Accounts & Seed Data

The system automatically seeds test data on first startup via Liquibase migrations:

### Pre-configured Accounts

#### Admin Account

- **Email**: `admin@skydive.com`
- **Password**: `Admin123!`
- **Role**: ADMIN
- **Permissions**: Full system access (all USER_*, DROPZONE_*, ROLE_*, PERMISSION_* permissions)
- **Status**: Active

#### Regular User Account

- **Email**: `user@skydive.com`
- **Password**: `User123!`
- **Role**: USER
- **Permissions**: Basic operations (USER_VIEW, DROPZONE_VIEW, USER_PASSWORD_CHANGE)
- **Status**: Active

### Seed Data Includes

- **Roles**: ADMIN, USER
- **Permissions**: 15+ granular permissions for users, dropzones, roles
- **Sample Dropzones**: Pre-configured skydiving locations
- **Role-Permission Mappings**: Pre-assigned permissions to roles

## AI Integration (OpenAI)

The Analysis Service uses OpenAI for generating intelligent weather forecasts.

### Configuration

To enable AI features, add your OpenAI API key:

**Option 1: Environment Variable**

```bash
export OPENAI_API_KEY=sk-your-api-key-here
docker-compose up
```

**Option 2: Docker Compose Override**

```yaml
# docker-compose.override.yml
services:
  analysis-service:
    environment:
      SPRING_AI_OPENAI_API_KEY: sk-your-api-key-here
```

**Option 3: Config Repository**

```yaml
# skydive-forecast-svc-config/analysis-service/application.yml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY:sk-your-api-key-here}
```

### AI Features

- **Weather Analysis**: Interprets weather data for skydiving suitability
- **Recommendations**: Generates natural language forecasts
- **Risk Assessment**: Evaluates conditions (wind, visibility, clouds)

**Note**: Without API key, the service will work but AI features will be disabled.

## CI/CD Pipeline

Each microservice includes GitHub Actions workflows for continuous integration:

### Automated Workflows

- **Build & Test**: Maven build, unit tests, integration tests
- **Code Quality**: JaCoCo coverage reports (70% minimum)
- **Docker Build**: Multi-stage Docker image builds
- **Security Scan**: Dependency vulnerability checks
- **Artifact Publishing**: Docker images to registry

### Pipeline Stages

```yaml
1. Checkout code
2. Setup Java 21
3. Maven build (mvn clean package)
4. Run tests (JUnit + Testcontainers)
5. Generate coverage report (JaCoCo)
6. Build Docker image
7. Push to container registry
```

### Local CI Simulation

```bash
# Run full CI pipeline locally
mvn clean verify
mvn jacoco:report  # Coverage report in target/site/jacoco/
```

## Production Deployment

### Kubernetes (Helm)

The `helm/` directory contains production-ready charts.

```bash
helm install skydive-forecast ./helm/skydive-forecast -n skydive-forecast --create-namespace
```

*Key Features*: Horizontal Pod Autoscaling (HPA), ConfigMaps/Secrets management, Ingress configuration.

### AWS (Terraform)

The `terraform/aws/` directory contains infrastructure-as-code for AWS deployment.

```bash
cd terraform/aws && terraform apply
```

*Architecture*: ECS Fargate cluster, Multi-AZ RDS PostgreSQL, ElastiCache Redis, MSK Kafka, Application Load Balancer.

## To Do

### Technical

- Implement database audit logging
- Create detailed sequence diagrams
- Implement Server-Sent Events (SSE) for real-time report notifications
- Enhance architecture diagrams

### Business Features

- Favourite Dropzones
- Wingsuit-specific report customizations
- Push notifications when async reports are complete
- Scheduled recurring weather reports

## Known Limitations

There are limitations in the project, some of which are due to a lack of time for implementation. Some technologies do not make sense in a project of this size. They are only there to showcase certain skills in the portfolio. This section lists those that I am aware of.

### Business Features

- **Business Features**: Some features are not implemented due to time constraints.
- **No real-time push notifications** users must poll for async report completion (no SSE implemented yet).
- **No scheduled reports** - reports are generated on-demand.
- **No favourite dropzones** - users can only generate reports for all dropzones.
- **No wingsuit-specific reports** - similar reports are generated for all users, not for ones with special expectations.

### Technical

- **Observability stack overhead:** 21 containers running locally - high RAM/CPU usage on typical developer machines.
- **Cold starts / initial latency** — JVM warm-up + service registration in Consul + database migrations can cause noticeable delays on first requests after restart (especially in local Docker Compose).
- **Data Persistence**: Local Docker Compose uses named volumes; `docker-compose down -v` wipes data.
- **Testing complexity** — Integration testing across microservices + Kafka + multiple DBs requires use of Testcontainers → slow & resource-intensive test suites. 
- **Complex cross-service queries** — Impossible to run SQL JOINs across User DB, Analysis DB, Location DB → reporting/analytics across domains requires additional aggregation services or data duplication.

## Troubleshooting

### Services not starting

- Check if required ports are available:
    - Services: 8080-8083
    - PostgreSQL: 15432-15434
    - Redis: 16379
    - Kafka: 19092, 29092
    - Zookeeper: 2181
    - Monitoring: 3000 (Grafana), 19090 (Prometheus), 13100 (Loki), 3200 (Tempo), 19000 (Kafka UI)
    - OpenTelemetry: 4317 (gRPC), 4318 (HTTP), 8889 (metrics)
- Verify Docker has enough resources (4GB RAM minimum recommended)
- Check logs: `docker-compose logs [service-name]`

### Database connection issues

- Wait for databases to be fully initialized (check health status)
- Verify database credentials in `docker-compose.yml`
- Check PostgreSQL logs: `docker-compose logs postgres-user postgres-analysis postgres-location`

### Kafka connectivity issues

- Ensure Zookeeper is running: `docker-compose logs zookeeper`
- Check Kafka logs: `docker-compose logs kafka`
- Kafka may take 30-60 seconds to fully initialize

### Swagger/OpenAPI issues

- Gateway aggregates OpenAPI docs from all services
- Individual service docs available at:
    - User: `http://localhost:8081/v3/api-docs/users`
    - Analysis: `http://localhost:8082/v3/api-docs/analyses`
    - Location: `http://localhost:8083/v3/api-docs/locations`

## License

This project is part of a portfolio demonstration.

## Contact

For questions or support, please contact me.
