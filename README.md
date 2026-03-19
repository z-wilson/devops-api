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

| Variable | Description      | Default  |
|----------|------------------|----------|
| ENV      | Environment name | dev-env  |
| PORT     | Application port | 5000     |

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

## Roadmap

- [x] Minimal Flask API  
- [x] Docker containerization  
- [x] Push image to AWS ECR  
- [x] Deploy to ECS (Fargate)  
- [ ] CI/CD pipeline (GitHub Actions)  
- [ ] Multi-environment deployment (dev/prod)  
- [ ] Infrastructure as Code (Terraform)  

---

## Notes

- Designed for learning and internal experimentation, not production.  
- Docker and ECS setup is kept to minimal cost, no load balancing or NAT gateways.  
