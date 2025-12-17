# FastAPI on AWS Fargate (ECS / EKS)

This repository contains a **bare-bones FastAPI application** with a single health-check endpoint:

```GET /health → {"status": "ok"}```


The purpose of this project is **not** application complexity, but to demonstrate a **clean, minimal deployment pipeline** for running containerized Python applications on AWS using:

- **Amazon ECR** (container registry)
- **AWS Fargate** (serverless container runtime)
- **Either ECS or EKS** as the orchestrator

The core goal is to understand and compare **Fargate-based deployment models**, not to build application features.

---

## Why this project exists

AWS offers multiple ways to run containers:

- ECS on EC2
- ECS on Fargate
- EKS on EC2
- EKS on Fargate

This repo focuses specifically on:

> **Running a FastAPI app on AWS *without managing servers***.

Fargate is the centerpiece:
- No EC2 instances to provision
- No OS patching
- No node autoscaling logic
- Pay only for running containers

---

## Application Overview

- **Framework:** FastAPI
- **Server:** Uvicorn
- **Endpoint:** `/health`
- **Purpose:** Load balancer health checks and end-to-end verification

Example response:

```json
{"status": "ok"}

## Repository Structure

.
├── app/
│   └── main.py          # FastAPI application
├── Dockerfile           # Container image definition
├── requirements.txt     # Python dependencies
└── README.md

## Running Locally
1. Install dependencies
pip install -r requirements.txt

2. Run the app
uvicorn app.main:app --reload --port 8001

3. Verify
curl http://localhost:8001/health

## Containerization

The app is packaged as a Docker image suitable for AWS Fargate.

Build locally
docker build -t fastapi-health .

Run locally
docker run -p 8001:8001 fastapi-health

## AWS Deployment Overview

The deployment flow is intentionally simple and cloud-native.

1. Build & push image to ECR

Create an ECR repository

Authenticate Docker to ECR

Push the image

aws ecr get-login-password \
  | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com

docker tag fastapi-health:latest <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/fastapi-health:latest
docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/fastapi-health:latest

## ECS task definition template (port 8001)
- A templated task definition lives at `task-def.template.json` with placeholders for account/region/roles.
- Render a concrete task def without hard-coding your ARNs by exporting your values and generating JSON:
  ```bash
  export AWS_ACCOUNT_ID=<your-account>
  export EXEC_ROLE_ARN=<arn:aws:iam::<acct>:role/ecsTaskExecutionRole>
  export TASK_ROLE_ARN=<arn:aws:iam::<acct>:role/fastapi-health-task-role> # optional; defaults to EXEC_ROLE_ARN
  export AWS_REGION=us-west-2
  scripts/render-task-def.sh > task-def.json
  aws ecs register-task-definition --region "$AWS_REGION" --cli-input-json file://task-def.json
  ```

## Deployment Options
Option A: ECS on Fargate

Best if you want simplicity and minimal Kubernetes exposure.

### High-level components:

ECS Cluster

Fargate Task Definition

ECS Service

Application Load Balancer

Request flow:

Client → ALB → Fargate Task → FastAPI container


No EC2 instances are created or managed.

Option B: EKS on Fargate

Best if you want Kubernetes APIs with serverless compute.

High-level components:

EKS Cluster

Fargate Profile

Kubernetes Deployment + Service / Ingress

AWS Load Balancer Controller

Request flow:

Client → ALB → Pod IP → FastAPI container


Pods run on AWS-managed Fargate infrastructure, not EC2 nodes.

Why Fargate?
Advantages

No server management

Strong isolation per workload

Simple mental model

Ideal for small services and APIs

Good fit for FastAPI

Tradeoffs

Higher cost at sustained scale

Cold start latency

No GPUs

Limited control over networking internals

This project intentionally chooses clarity over optimization.

What this project is not

Not a production-ready reference architecture

Not a microservices framework

Not opinionated about Terraform vs CDK vs console

Not optimized for cost or performance

It is a learning and demonstration scaffold.

Success Criteria

The project is considered successful when:

The container image is stored in ECR

The app runs on Fargate

A public AWS load balancer responds with:

```curl http://<alb-dns-name>/health
{"status":"ok"}```
