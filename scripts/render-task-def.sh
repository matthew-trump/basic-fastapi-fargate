#!/usr/bin/env bash
set -euo pipefail

AWS_REGION=${AWS_REGION:-us-west-2}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}
EXEC_ROLE_ARN=${EXEC_ROLE_ARN:?Set EXEC_ROLE_ARN}
TASK_ROLE_ARN=${TASK_ROLE_ARN:-$EXEC_ROLE_ARN}
IMAGE_TAG=${IMAGE_TAG:-latest}
LOG_GROUP=${LOG_GROUP:-/ecs/fastapi-health}
CPU=${CPU:-256}
MEMORY=${MEMORY:-512}

cat <<EOF
{
  "family": "fastapi-health",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "$CPU",
  "memory": "$MEMORY",
  "executionRoleArn": "$EXEC_ROLE_ARN",
  "taskRoleArn": "$TASK_ROLE_ARN",
  "containerDefinitions": [
    {
      "name": "fastapi-health",
      "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fastapi-health:${IMAGE_TAG}",
      "portMappings": [{ "containerPort": 8001, "hostPort": 8001, "protocol": "tcp" }],
      "essential": true,
      "healthCheck": {
        "command": ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8001/health')\" || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 10
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "$LOG_GROUP",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF
