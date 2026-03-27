# DevOps API Demo

## Overview

This project is a minimal Python Flask API designed to demonstrate end-to-end DevOps workflows.
It’s intended for learning containerization, CI/CD, and deployment to AWS from a Windows environment.

The focus is on packaging, deployment, and operational workflows, not the app itself. The setup is intentionally minimal (no load balancing or NAT gateways) to keep costs low while demonstrating a full end-to-end pipeline.

---

## Tech Stack

- Python 3.9+ (Flask)  
- Docker
- AWS ECS / Fargate
- GitHub Actions  

---

## Current Functionality

The API exposes two endpoints:

- `/` → Returns basic status and version  
- `/time` → Returns current time and virtual environment info  

---

## Running Locally

### 1. Create & activate virtual environment

PowerShell:  

    python -m venv venv  
    .\venv\Scripts\Activate.ps1  

Command Prompt:  

    venv\Scripts\activate.bat  

### 2. Install dependencies

    pip install -r requirements.txt  

### 3. Run the app

    python app.py  

### 4. Test endpoints

    curl http://localhost:5000/  
    curl http://localhost:5000/time  

---

## Environment Variables

| Variable     | Description                                      | Default |
|--------------|--------------------------------------------------|---------|
| ENV          | Environment name                                 | dev-env |
| PORT         | Application port                                 | 5000    |
| APP_VERSION  | Application version (set by CI/CD from Git tag)  | v1.0    |

---

## Docker

### Build image

    docker build -t devops-api .

### Run container

    docker run -p 5000:5000 devops-api

### Authenticate with ECR

    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

### Tag container

    docker tag devops-api:latest <account-id>.dkr.ecr.<region>.amazonaws.com/devops-api:latest

### Push container

    docker push <account-id>.dkr.ecr.<region>.amazonaws.com/devops-api:latest

---

## GitHub Secrets Required

Before the CI/CD pipeline will run, add the following secret to your GitHub repo (Settings → Secrets and variables → Actions):

| Secret           | Description                      |
|------------------|----------------------------------|
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account number |

The pipeline authenticates to AWS using OIDC — no long-lived access keys required. The IAM role ARNs are hardcoded in the workflow and assumed at runtime (`github-oidc-devops-api-dev` for dev, `github-oidc-devops-api` for prod). Each role must have a trust policy allowing `token.actions.githubusercontent.com` as the federated identity provider, scoped to this repository.

---

## CI/CD Pipeline

This project uses GitHub Actions to automate build and deployment to AWS Elastic Container Service (ECS).

### Triggers

| Event | Environment |
| --- | --- |
| Push to `main` | Dev |
| Push tag `v*` | Prod |

Example (dev):

    git push origin main

Example (prod):

    git tag v1.8
    git push origin v1.8

---

### What the pipeline does

**Dev** (on push to `main`):

1. Builds a Docker image from the latest code
2. Tags the image with the commit SHA
3. Pushes the image to ECR (`devops-api-dev`)
4. Creates a new ECS task definition revision
5. Injects `APP_VERSION` = commit SHA
6. Deploys to `devops-cluster-dev`

**Prod** (on `v*` tag):

1. Builds a Docker image from the latest code
2. Tags the image with the Git tag (for example v1.8)
3. Pushes the image to ECR (`devops-api`)
4. Creates a new ECS task definition revision
5. Injects `APP_VERSION` = Git tag
6. Deploys to `devops-cluster`

---

### Versioning

`APP_VERSION` is automatically injected at deploy time:

| Environment | Value |
| --- | --- |
| Dev | Commit SHA |
| Prod | Git tag (e.g. `v1.8`) |

---

### Deployment behavior

- Each tag results in a new ECS task definition revision  
- ECS performs a rolling deployment:
  - Starts new task(s)  
  - Waits for health checks  
  - Stops old task(s)  
- No downtime (assuming health checks pass)

---

## Deployment

### 1. Dev deployment — push to main

Pushing to `main` triggers the dev pipeline automatically.

    git add .
    git commit -m "Update feature"
    git push origin main

### 2. Prod deployment — create and push a Git tag

Pushing a `v*` tag triggers the prod pipeline.

    git tag v1.8
    git push origin v1.8

### 3. Monitor deployment

- GitHub Actions workflow run
- AWS ECS service deployment status

---

## Verify Deployment

After deployment completes:

- Check ECS service*:
  - Desired count = 1
  - Running count = 1
- Confirm task definition revision updated
- Find the public IP in AWS console: ECS → Clusters → select cluster → Tasks tab → click the running task → Network section → Public IP

*Optional: AWS CLI

    # confirm desired count of service tasks
    
    # prod
    aws ecs describe-services \
        --cluster devops-cluster \
        --services devops-api-service \
        --region us-east-2 \
        --query "services[0].{desired:desiredCount,running:runningCount}"

    # dev
    aws ecs describe-services \
        --cluster devops-cluster-dev \
        --services devops-api-service-dev \
        --region us-east-2 \
        --query "services[0].{desired:desiredCount,running:runningCount}"

    # confirm task definition revision (check the ARN increments after each deploy)

    # prod
    aws ecs describe-services \
        --cluster devops-cluster \
        --services devops-api-service \
        --region us-east-2 \
        --query "services[0].taskDefinition"

    # dev
    aws ecs describe-services \
        --cluster devops-cluster-dev \
        --services devops-api-service-dev \
        --region us-east-2 \
        --query "services[0].taskDefinition"

    # Get the public IP of the running task

    # prod example
    TASK_ARN=$(aws ecs list-tasks \
        --cluster devops-cluster \
        --service-name devops-api-service \
        --region us-east-2 \
        --query "taskArns[0]" \
        --output text)

    ENI_ID=$(aws ecs describe-tasks \
        --cluster devops-cluster \
        --tasks $TASK_ARN \
        --region us-east-2 \
        --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" \
        --output text)

    aws ec2 describe-network-interfaces \
        --network-interface-ids $ENI_ID \
        --region us-east-2 \
        --query "NetworkInterfaces[0].Association.PublicIp" \
        --output text

- Test endpoint:

    PUBLIC_IP=$(aws ec2 describe-network-interfaces \
        --network-interface-ids $ENI_ID \
        --region us-east-2 \
        --query "NetworkInterfaces[0].Association.PublicIp" \
        --output text)

    curl http://$PUBLIC_IP:5000/

**Dev** — expected response:

    {"env": "dev", "version": "<commit-sha>"}

**Prod** — expected response:

    {"env": "prod", "version": "v1.11"}

---

## Troubleshooting

### Deployment triggered but version did not update

- Ensure a new Git tag was pushed  
- Confirm GitHub Actions completed successfully  
- Verify ECS service updated to a new task definition revision  

### App version not changing

- Check that APP_VERSION is being set in the task definition  
- Verify the application reads it using:
  os.getenv("APP_VERSION")  

### Task stuck in PENDING or PROVISIONING

- Check the subnet assigned to the ECS service has a route to the internet (this setup uses no NAT, so a public subnet with auto-assign public IP enabled is required)
- Verify the security group allows outbound traffic so the task can pull the image from ECR
- Confirm the task execution role has `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, and `logs:CreateLogStream` permissions

### Container unreachable

- Confirm container port matches task definition (for example 5000)
- Verify load balancer target group health (if applicable)

---

## Cleanup Guidance

To stop incurring costs when not actively using the environment:

- Set ECS service desired count to 0 to stop running tasks (Cluster -> Service -> Update service -> set Desired Tasks to 0)*
- Delete unused ECS services if no longer needed
- Remove old ECR images if storage grows
- Ensure no orphaned resources remain (tasks, target groups, logs)

*Optional: AWS CLI

    # set desired count of service tasks

    aws ecs update-service --cluster devops-cluster --service devops-api-service --desired-count 0
    aws ecs update-service --cluster devops-cluster-dev --service devops-api-service-dev --desired-count 0

    # confirm desired count of service tasks

    aws ecs describe-services \
        --cluster devops-cluster \
        --services devops-api-service \
        --region us-east-2 \
        --query "services[0].{desired:desiredCount,running:runningCount}"

    aws ecs describe-services \
        --cluster devops-cluster-dev \
        --services devops-api-service-dev \
        --region us-east-2 \
        --query "services[0].{desired:desiredCount,running:runningCount}"

---

## Features

- [x] Minimal Flask API  
- [x] Docker containerization  
- [x] Push image to AWS ECR  
- [x] Deploy to ECS (Fargate)  
- [x] CI/CD pipeline (GitHub Actions)  
- [x] Multi-environment deployment (dev/prod)

Infrastructure as Code (Terraform) for these resources will be covered in a separate repository which will be linked here upon completion.
