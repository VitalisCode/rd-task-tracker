rd-task-tracker/
├── .gitlab-ci.yml          # CI/CD pipeline definition
├── .gitignore
├── README.md
│
├── services/
│   ├── api/                # FastAPI backend
│   └── frontend/           # Nginx frontend
│
├── helm/
│   ├── api/                # Helm chart for API
│   └── frontend/           # Helm chart for Frontend
│
├── terraform/              # EKS cluster infra
├── argocd/                 # ArgoCD app manifests
└── monitoring/             # Grafana, Loki, ELK configs

===============================================

 Build and test locally
# From project root
colima start
docker compose build

# Run both services
docker compose up -d

# Check they're healthy
docker compose ps
================================================
# Test API health
curl http://localhost:8000/health
# → {"status":"healthy","service":"api"}

# Create a task
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Write unit tests", "project": "RD-2024", "status": "pending"}'

# List tasks
curl http://localhost:8000/tasks

# Open frontend
open http://localhost:8080   # or visit in browser

===============================================
# AWS CLI login
# Option 1: configure AWS credentials interactively
aws configure

# Option 2: set credentials from environment variables
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
export AWS_REGION=eu-central-1

# If you have temporary credentials, also set:
export AWS_SESSION_TOKEN="YOUR_AWS_SESSION_TOKEN"

# Validate AWS CLI login
aws sts get-caller-identity --query Account --output text

Set up AWS ECR repositories first
# Create ECR repos
aws ecr create-repository \
  --repository-name rd-task-tracker/api \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true

aws ecr create-repository \
  --repository-name rd-task-tracker/frontend \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true

=======================================================
# Bootstrap remote state 

# Create S3 bucket for state
aws s3api create-bucket \
  --bucket rd-task-tracker-tfstate \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

# Enable versioning (recover from bad applies)
aws s3api put-bucket-versioning \
  --bucket rd-task-tracker-tfstate \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket rd-task-tracker-tfstate \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name rd-task-tracker-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1


===========================
terraform folder:

terraform/
├── main.tf              # Root module — wires everything together
├── variables.tf         # Input variables
├── outputs.tf           # Outputs (cluster endpoint, kubeconfig etc.)
├── versions.tf          # Provider version locks
└── modules/
    ├── vpc/             # VPC, subnets, NAT gateway
    ├── eks/             # EKS cluster + node groups
    └── iam/             # IAM roles for cluster & nodes

=====================
Apply the infrastructure
cd terraform

# Initialise — downloads providers, connects to S3 backend
terraform init

# Preview what will be created (always do this first)
terraform plan -out=tfplan

# Apply — takes ~15 minutes for EKS
terraform apply tfplan

=============================================================

## ONCE TERRAFORM IS DONE START DOING THIS LOCALLY

configure kubectl:
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name rd-task-tracker

# Verify you can see the cluster
kubectl get nodes
kubectl get namespaces


============================================================
# ArgoCD steup

#### Step 1 >> Create argocd namespace
kubectl create namespace argocd
kubectl create namespace rd-staging

# Install ArgoCD in the cluster
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Wait for it to be ready
kubectl wait --for=condition=available \
  deployment/argocd-server -n argocd --timeout=120s

# Get the initial admin password
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo  

====
#### Step 2 >> Connect GitLab repo to ArgoCD

# first install argocd on ur locals incase you don't have it, with these commands below
VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
argocd version
# Port-forward the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080 — login with admin + password above

# then login to argocd Note make sure the argocd is running.

argocd login localhost:8080 \
  --username admin \
  --password 3hrhu4****iJfyG \
  --insecure

# then run to add your code repo to argocd
argocd repo add https://github.com/VitalisCode/rd-task-tracker.git \
  --username VitalisCode \
  --password github_patSLT0********aBV4X*****mG

# Apply both ArgoCD apps
kubectl apply -f argocd/stage/api-app.yaml
kubectl apply -f argocd/stage/frontend-app.yaml


# Watch them sync
argocd app list
argocd app get rd-api-staging
argocd app get rd-frontend-staging


=================================================================
=================================================================

# Store Secrets via HashiCorp.

## Step 1
# just install helm locally first
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Store secrets via AWS Secrets Manager

## Step 1 — create the secret
aws secretsmanager create-secret \
  --name rd-task-tracker/api \
  --region $AWS_REGION \
  --secret-string '{"SECRET_KEY":"super-secret-production-key","DB_PASSWORD":"pg-pass-123","JWT_SECRET":"jwt-$(openssl rand -hex 16)"}'

## Step 2 — configure your deployment
# Do not load secrets inside the app. Instead, inject these values into the
# Kubernetes pod as environment variables when the container starts.
# For example, use an AWS Secrets Manager to Kubernetes secret sync or injector.

# Exporting values here is only for local testing.
export AWS_REGION=eu-central-1

# In production, have your platform inject SECRET_KEY, DB_PASSWORD, and JWT_SECRET
# into the pod environment instead of having the app call AWS Secrets Manager.