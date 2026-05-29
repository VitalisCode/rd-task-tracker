Developer Push
      ↓
Linting (Ruff)
      ↓
Unit Tests (pytest)
      ↓
Security Scan
      ↓
SonarQube Analysis
      ↓
Build Docker Image
      ↓
Container Scan
      ↓
Push Image Registry
      ↓
Deploy to Kubernetes


===================

Build Image
     │
     ▼
Push Image
     │
     ▼
Update values-stage.yaml
     │
     ▼
ArgoCD Staging Sync
     │
     ▼
GitHub Approval Required
     │
     ▼
Update values-prod.yaml
     │
     ▼
ArgoCD Production Sync

============================

Validate
├── Ruff
├── Bandit
├── Gitleaks
│
├── Upload Reports
│
▼
Manual Approval
│
▼
Build Docker Images
│
▼
Push to ECR
│
▼
Deploy Staging
│
▼
Production Approval
│
▼
Deploy Production




