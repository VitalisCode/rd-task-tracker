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
  --password github_patSLTQ0********mhTEaBV4XK********mG8Om

# Apply both ArgoCD apps
kubectl apply -f argocd/stage/api-app.yaml
kubectl apply -f argocd/stage/frontend-app.yaml


# Watch them sync
argocd app list
argocd app get rd-api-staging
argocd app get rd-frontend


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

# Create vault namespace
kubectl create namespace vault

# Install Vault in main mode for demo on the cluster via Helm
# (in production you'd use HA mode with DynamoDB backend)
helm install vault hashicorp/vault \
  --namespace vault \
  --set "server.main.enabled=true" \
  --set "injector.enabled=true" \
  --set "server.main.mainRootToken=root"
# Wait for vault to be ready
kubectl wait --for=condition=ready \
  pod/vault-0 -n vault --timeout=60s

# Verify injector is running
kubectl get pods -n vault

============
## Step 2 — Configure Vault
# Exec into the Vault pod
kubectl exec -it vault-0 -n vault -- /bin/sh

# Now inside the Vault pod, run all of this:
# Login with main root token
vault login root

# ── 1. Enable the KV secrets engine ─────────────────────────────
vault secrets enable -path=secret kv-v2

# ── 2. Write your app secrets ────────────────────────────────────
vault kv put secret/rd-task-tracker/api \
  secret_key="super-secret-production-key-$(date +%s)" \
  db_password="pg-pass-$(date +%s)" \
  jwt_secret="jwt-$(openssl rand -hex 32)"

# Verify it was written
vault kv get secret/rd-task-tracker/api

# ── 3. Enable Kubernetes auth method ────────────────────────────
vault auth enable kubernetes

# ── 4. Configure K8s auth (tells Vault how to verify pod tokens) ─
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert="@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" \
  issuer="https://kubernetes.default.svc.cluster.local"

# ── 5. Create a policy — what secrets rd-api is allowed to read ──
vault policy write rd-api-policy - <<EOF
path "secret/data/rd-task-tracker/api" {
  capabilities = ["read"]
}

path "secret/data/rd-task-tracker/api/*" {
  capabilities = ["read"]
}
EOF

# ── 6. Create a role — binds K8s service account to the policy ───
vault write auth/kubernetes/role/rd-api \
  bound_service_account_names=rd-api-sa \
  bound_service_account_namespaces=rd-staging \
  policies=rd-api-policy \
  ttl=1h

# Verify role was created
vault read auth/kubernetes/role/rd-api

# Exit the pod
exit

================================