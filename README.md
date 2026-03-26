# DevOps API Demo

## Overview

This project is a minimal Python Flask API designed to demonstrate end-to-end DevOps workflows.  
It’s intended for learning containerization, CI/CD, and deployment to AWS from a Windows environment.

The focus is on packaging, deployment, and operational workflows, not the app itself.

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

### Tag container

    docker tag devops-api:latest <account-id>.dkr.ecr.<region>.amazonaws.com/devops-api:latest

### Push container

    docker push <account-id>.dkr.ecr.<region>.amazonaws.com/devops-api:latest

---

## GitHub Secrets Required

Before the CI/CD pipeline will run, add the following secret to your GitHub repo (Settings → Secrets and variables → Actions):

| Secret           | Description                        |
|------------------|------------------------------------|
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account number   |

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

### Create a new release

#### 1. Commit and push your changes to the main branch

    git add .  
    git commit -m "Update feature"  
    git push origin main  

#### 2. Create and push a Git tag

    git tag v1.8  
    git push origin v1.8  

#### 3. Monitor deployment

- GitHub Actions workflow run
- AWS ECS service deployment status

---

## Verify Deployment

After deployment completes:

- Check ECS service:
  - Desired count = 1  
  - Running count = 1  
- Confirm task definition revision updated  
- Verify environment variable:
  APP_VERSION = v1.8  
- Find the public IP: ECS → Clusters → `devops-cluster` → Tasks tab → click the running task → Network section → Public IP

- Test endpoint:

    curl http://PUBLIC_IP:5000/

Expected response includes:

    Version: v1.8

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

    aws ecs update-service --cluster devops-cluster --service devops-api-service --desired-count 0

---

## Roadmap

- [x] Minimal Flask API  
- [x] Docker containerization  
- [x] Push image to AWS ECR  
- [x] Deploy to ECS (Fargate)  
- [x] CI/CD pipeline (GitHub Actions)  
- [x] Multi-environment deployment (dev/prod)
- [ ] Infrastructure as Code (Terraform)  

---

## Notes

- Designed for learning and internal experimentation, not production.  
- Docker and ECS setup is kept to minimal cost, no load balancing or NAT gateways.  
