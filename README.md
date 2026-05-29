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



# ══════════════════════════════════════════════════════

# DEPLOY STAGING

# ══════════════════════════════════════════════════════

deploy-staging:
runs-on: ubuntu-latest

needs:
- build-scan-push-api
- build-scan-push-frontend

if: github.ref == 'refs/heads/main'

environment:
name: staging

steps:
- uses: actions/checkout@v4
with:
token: ${{ secrets.GITHUB_TOKEN }}




