terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "container_image_tag" {
  type        = string
  description = "The unique Git SHA tag of the image pushed to GHCR"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "floci"
  secret_key                  = "floci"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Instruct the provider to route network and compute APIs into Floci
  endpoints {
    ec2      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
    ecs      = "http://localhost:4566"
  }
}

# ==============================================================================
# 1. Minimal Networking Architecture
# ==============================================================================
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# ==============================================================================
# 2. ECS Cluster Definition
# ==============================================================================
resource "aws_ecs_cluster" "starlette_cluster" {
  name = "poc-starlette-cluster"
}

# ==============================================================================
# 3. ECS Task Definition (The Blueprints for your Starlette Container)
# ==============================================================================
resource "aws_ecs_task_definition" "starlette_app" {
  family                   = "starlette-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::000000000000:role/mock-execution-role"

  container_definitions = jsonencode([
    {
      name      = "starlette-api"
      image     = "ghcr.io/${var.container_image_tag}" # Injected from your pipeline execution context
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        { name = "PYTHONUNBUFFERED", value = "1" }
      ]
    }
  ])
}

# ==============================================================================
# 4. ECS Service (Handles Instance Counting and Lifecycle Management)
# ==============================================================================
resource "aws_ecs_service" "starlette_service" {
  name            = "starlette-web-service"
  cluster         = aws_ecs_cluster.starlette_cluster.id
  task_definition = aws_ecs_task_definition.starlette_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    assign_public_ip = true
  }
}