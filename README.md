Developer Push / Pull Request
            │
            ▼
 ┌─────────────────────────┐
 │   Validation Stage      │
 └─────────────────────────┘
            │
            ├── Ruff (Linting)
            ├── Unit Tests (Pytest)
            ├── Bandit (SAST)
            ├── Gitleaks (Secrets Scan)
            ├── SonarQube Analysis
            └── Upload Reports
            │
            ▼
     Manual Approval
            │
            ▼
 ┌─────────────────────────┐
 │      Build Stage        │
 └─────────────────────────┘
            │
            ├── Build Docker Image
            ├── Container Security Scan
            │     (Trivy/Grype)
            └── Tag Image
            │
            ▼
        Push to ECR
            │
            ▼
 ┌─────────────────────────┐
 │   Staging Deployment    │
 └─────────────────────────┘
            │
            ├── Update values-stage.yaml
            ├── Commit to GitOps Repo
            ├── ArgoCD Sync (Staging)
            ├── Verify Rollout
            ├── Verify Pods Healthy
            ├── Verify Service Endpoint
            └── Smoke Tests
            │
            ▼
    Production Approval
            │
            ▼
 ┌─────────────────────────┐
 │ Production Deployment   │
 └─────────────────────────┘
            │
            ├── Update values-prod.yaml
            ├── Commit to GitOps Repo
            ├── ArgoCD Sync (Production)
            ├── Verify Rollout
            ├── Verify Pods Healthy
            ├── Verify Service Endpoint
            └── Smoke Tests
            │
            ▼
         Monitoring
            │
            ├── Prometheus
            ├── Grafana
            ├── CloudWatch
            └── AlertManager








Developer Push / Pull Request
            │
            ▼
 ┌─────────────────────────┐
 │   Validation Stage      │
 └─────────────────────────┘
            │
            ├── Ruff (Linting)
            ├── Unit Tests (Pytest)
            ├── Bandit (SAST)
            ├── Gitleaks (Secrets Scan)
            ├── SonarQube Analysis
            └── Upload Reports
            │
            ▼
     Manual Approval
            │
            ▼
 ┌─────────────────────────┐
 │      Build Stage        │
 └─────────────────────────┘
            │
            ├── Build Docker Image
            ├── Container Security Scan
            │     (Trivy/Grype)
            └── Tag Image
            │
            ▼
        Push to ECR
            │
            ▼
 ┌─────────────────────────┐
 │   Staging Deployment    │
 └─────────────────────────┘
            │
            ├── Update values-stage.yaml
            ├── Commit to GitOps Repo
            ├── ArgoCD Sync (Staging)
            ├── Verify Rollout
            ├── Verify Pods Healthy
            ├── Verify Service Endpoint
            └── Smoke Tests
            │
            ▼
    Production Approval
            │
            ▼
 ┌─────────────────────────┐
 │ Production Deployment   │
 └─────────────────────────┘
            │
            ├── Update values-prod.yaml
            ├── Commit to GitOps Repo
            ├── ArgoCD Sync (Production)
            ├── Verify Rollout
            ├── Verify Pods Healthy
            ├── Verify Service Endpoint
            └── Smoke Tests