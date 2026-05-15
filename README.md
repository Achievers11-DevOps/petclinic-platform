# Spring PetClinic Microservices — Project D Deployment Guide
### Achievers11-DevOps | Greg Odunmbaku | May 2026

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Repository Structure](#repository-structure)
5. [Phase-by-Phase Deployment](#phase-by-phase-deployment)
6. [Challenges & Solutions](#challenges--solutions)
7. [Access Points](#access-points)
8. [Cost Management](#cost-management)
9. [CI/CD — Triggering a Build](#cicd--triggering-a-build)

---

## Project Overview

| Item | Value |
|---|---|
| AWS Account ID | 118821711881 |
| Region | us-east-1 (N. Virginia) |
| EKS Cluster | petclinic-eks |
| Namespace | petclinic |
| ECR Registry | 118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic |
| Domain | https://gregddevops.com.ng |
| Route 53 Hosted Zone | Z10395433FWC00PFCKRCW |
| Platform Repo | Achievers11-DevOps/petclinic-platform |
| App Repo | Achievers11-DevOps/petclinic-app |

---

## Architecture

```
Internet
    │
    ▼
Route 53 (gregddevops.com.ng)
    │
    ▼
AWS ALB (HTTPS/443) ← ACM Certificate
    │
    ▼
EKS Cluster (petclinic-eks) — 2x m7i-flex.large nodes
    │
    ├── petclinic namespace
    │     ├── config-server
    │     ├── discovery-server
    │     ├── api-gateway
    │     ├── customers-service ─┐
    │     ├── vets-service       ├── RDS MySQL (us-east-1)
    │     ├── visits-service    ─┘
    │     ├── genai-service ──── Secrets Manager (OpenAI key)
    │     └── admin-server
    │
    ├── argocd namespace
    │     └── ArgoCD (watching petclinic-platform dev branch)
    │
    └── monitoring namespace
          ├── Prometheus (21 targets)
          └── Grafana (28 dashboards)

ECR (us-east-1) ← crane copied from af-south-1
Secrets Manager ← ESO (External Secrets Operator) → K8s Secrets
```

---

## Prerequisites

### Tools Required
```bash
# Verify all tools installed
aws --version          # AWS CLI v2
kubectl version        # kubectl
helm version           # Helm 3
eksctl version         # eksctl
crane version          # crane (google/go-containerregistry)
terraform version      # Terraform
docker --version       # Docker
```

### Install crane (if not installed)
```bash
curl -sL "https://github.com/google/go-containerregistry/releases/download/v0.19.1/go-containerregistry_Linux_x86_64.tar.gz" | tar -xz crane
sudo mv crane /usr/local/bin/crane
crane version
```

### AWS Configuration
```bash
aws configure
# AWS Access Key ID: YOUR_KEY
# AWS Secret Access Key: YOUR_SECRET
# Default region: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

---

## Repository Structure

```
petclinic-platform/
├── terraform/              # VPC, EKS, RDS, ECR infrastructure
├── helm/
│   └── petclinic-service/  # Reusable Helm chart for all 8 services
├── helm-values/            # Per-service value overrides
│   ├── config-server.yaml
│   ├── discovery-server.yaml
│   ├── api-gateway.yaml
│   ├── customers-service.yaml
│   ├── vets-service.yaml
│   ├── visits-service.yaml
│   ├── genai-service.yaml
│   ├── admin-server.yaml
│   └── dev.yaml            # Shared dev environment values
├── argocd/
│   └── applicationset.yaml # ArgoCD ApplicationSet for all 8 services
├── k8s/
│   └── external-secrets/   # ESO ClusterSecretStore + ExternalSecrets
└── scripts/
    ├── start-env.sh         # Start RDS + scale up nodes
    ├── stop-env.sh          # Stop RDS + scale down nodes
    └── env-status.sh        # Check environment status
```

---

## Phase-by-Phase Deployment

### Pre-flight — Fix Region Configuration

The Terraform files defaulted to `us-east-1` but the backend and variables needed verification.

```bash
cd ~/Petclinic-Platform-G11/petclinic-platform/terraform

# Verify backend.tf points to us-east-1
cat backend.tf

# Verify variables.tf default region
grep -A2 'variable "region"' variables.tf
```

**Claude Code Prompt:**
```
You are deploying Spring PetClinic Microservices for team Achievers11-DevOps.
Work in the current directory: ~/Petclinic-Platform-G11/petclinic-platform
Region: us-east-1
Cluster: petclinic-eks
Namespace: petclinic
ECR: 118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic
Domain: gregddevops.com.ng
Route 53 Zone: Z10395433FWC00PFCKRCW
Run all 13 deployment phases.
```

---

### Phase 1 — Terraform (VPC, EKS, RDS, ECR)

```bash
cd terraform/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Expected output:**
- VPC: `petclinic-vpc` (10.0.0.0/16, 2 public subnets)
- EKS: `petclinic-eks` (Kubernetes 1.32)
- RDS: `petclinic-mysql.co38siyqqwll.us-east-1.rds.amazonaws.com` (MySQL 8.0)
- ECR: 8 repositories under `petclinic/`

**Connect kubectl:**
```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-eks
kubectl get nodes
```

> 📸 **Screenshot:** `kubectl get nodes` showing nodes Ready

---

### Phase 2 — Namespaces

```bash
kubectl create namespace petclinic
kubectl create namespace argocd
kubectl create namespace monitoring
kubectl get namespaces
```

> 📸 **Screenshot:** `kubectl get namespaces` showing all 3 namespaces

---

### Phase 3 — AWS Load Balancer Controller

```bash
# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://aws-lbc-iam-policy.json

# Install via Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=petclinic-eks \
  --set serviceAccount.create=true \
  --set region=us-east-1 \
  --set vpcId=$(aws eks describe-cluster --name petclinic-eks --query 'cluster.resourcesVpcConfig.vpcId' --output text)

# Verify
kubectl get pods -n kube-system | grep aws-load-balancer
```

---

### Phase 4 — External Secrets Operator (ESO)

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n kube-system \
  --set installCRDs=true

# Create ClusterSecretStore
kubectl apply -f k8s/external-secrets/secret-store.yaml

# Verify
kubectl get clustersecretstore
```

> ⚠️ **Note:** ClusterSecretStore MUST point to `us-east-1` not `af-south-1`

---

### Phase 5 — Secrets Manager

```bash
# Verify secrets exist
aws secretsmanager describe-secret \
  --secret-id petclinic/database-credentials \
  --region us-east-1

aws secretsmanager describe-secret \
  --secret-id petclinic/openai-api-key \
  --region us-east-1
```

---

### Phase 6 — ECR Pull Secret

```bash
# Create ECR pull secret in petclinic namespace
kubectl create secret docker-registry ecr-pull-secret \
  --docker-server=118821711881.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n petclinic
```

---

### Phase 7 — Copy Images af-south-1 → us-east-1 (crane)

Images were already built and pushed to `af-south-1` ECR (`petclinic-dev/`).
We used `crane` to copy them cross-region to `us-east-1` (`petclinic/`).

```bash
# Authenticate crane to both registries
aws ecr get-login-password --region af-south-1 | \
  crane auth login \
  118821711884.dkr.ecr.af-south-1.amazonaws.com \
  --username AWS --password-stdin

aws ecr get-login-password --region us-east-1 | \
  crane auth login \
  118821711881.dkr.ecr.us-east-1.amazonaws.com \
  --username AWS --password-stdin

# Copy all 8 images
for SERVICE in config-server discovery-server api-gateway \
  customers-service vets-service visits-service \
  genai-service admin-server; do
  echo "Copying $SERVICE..."
  crane copy \
    118821711881.dkr.ecr.af-south-1.amazonaws.com/petclinic-dev/$SERVICE:latest \
    118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic/$SERVICE:latest
  echo "$SERVICE done"
done

# Verify
for SERVICE in config-server discovery-server api-gateway \
  customers-service vets-service visits-service \
  genai-service admin-server; do
  COUNT=$(aws ecr describe-images --repository-name petclinic/$SERVICE \
    --region us-east-1 --query 'length(imageDetails)' --output text)
  echo "petclinic/$SERVICE: $COUNT images"
done
```

> 📸 **Screenshot:** All 8 services showing image counts in us-east-1

---

### Phase 8 — Helm Deploy All 8 Services

```bash
RDS_ENDPOINT="petclinic-mysql.co38siyqqwll.us-east-1.rds.amazonaws.com"
ECR="118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic"
CHART="./helm/petclinic-service"
VALUES="./helm-values"

# Deploy config-server first
helm upgrade --install config-server $CHART \
  -n petclinic \
  -f $VALUES/config-server.yaml \
  -f $VALUES/dev.yaml \
  --set image.repository=$ECR/config-server \
  --set image.tag=latest
kubectl rollout status deployment/config-server -n petclinic --timeout=5m

# Deploy discovery-server second
helm upgrade --install discovery-server $CHART \
  -n petclinic \
  -f $VALUES/discovery-server.yaml \
  -f $VALUES/dev.yaml \
  --set image.repository=$ECR/discovery-server \
  --set image.tag=latest
kubectl rollout status deployment/discovery-server -n petclinic --timeout=5m

# Deploy remaining 6 services
for SERVICE in api-gateway customers-service visits-service \
  vets-service genai-service admin-server; do
  helm upgrade --install $SERVICE $CHART \
    -n petclinic \
    -f $VALUES/$SERVICE.yaml \
    -f $VALUES/dev.yaml \
    --set image.repository=$ECR/$SERVICE \
    --set image.tag=latest
done

# Verify all pods
kubectl get pods -n petclinic
```

> 📸 **Screenshot:** All 8 pods showing `1/1 Running`

---

### Phase 9 — ArgoCD Install + ApplicationSet

```bash
# Install ArgoCD
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Apply ApplicationSet (all 8 services, watching dev branch)
kubectl apply -f argocd/applicationset.yaml

# Verify all apps
kubectl get applications -n argocd
```

**ArgoCD admin password:** `VCnLcyGY7MB09Xds`

**ArgoCD UI:**
```
http://ab0c6a7cb31114136811e3770ab7a7d6-1941241676.us-east-1.elb.amazonaws.com
```

> 📸 **Screenshot:** ArgoCD dashboard showing 8/8 apps Synced + Healthy

---

### Phase 10 — Ingress + HTTPS + Route 53

```bash
# Apply ingress manifest (creates ALB via AWS Load Balancer Controller)
kubectl apply -f k8s/ingress.yaml

# Get ALB DNS name
kubectl get ingress -n petclinic

# Update Route 53 alias record to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id Z10395433FWC00PFCKRCW \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "gregddevops.com.ng",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "ALB_DNS_HERE",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'

# Verify
curl -I https://gregddevops.com.ng
```

> 📸 **Screenshot:** Browser showing `https://gregddevops.com.ng` with PetClinic UI

---

### Phase 11 — Monitoring (Prometheus + Grafana)

```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Wait for all pods
kubectl get pods -n monitoring

# Access Grafana (use 3002 if 3000 is in use locally)
kubectl port-forward svc/monitoring-grafana -n monitoring 3002:80
```

**Grafana:** `http://localhost:3002` — `admin / admin123`
**Prometheus:** `http://localhost:9090`

> 📸 **Screenshot:** Grafana dashboard showing cluster metrics

---

### Phase 12 — Commit to Dev Branch

```bash
cd ~/Petclinic-Platform-G11/petclinic-platform

git checkout dev
git add helm-values/customers-service.yaml \
        helm-values/vets-service.yaml \
        helm-values/visits-service.yaml \
        argocd/applicationset.yaml \
        k8s/ingress.yaml

git commit -m "GPM-226: fix RDS endpoint and ArgoCD namespace for petclinic us-east-1"
git push origin dev
```

---

### Phase 13 — Final Verification

```bash
# All nodes
kubectl get nodes

# All petclinic pods
kubectl get pods -n petclinic

# All ArgoCD apps
kubectl get applications -n argocd

# All monitoring pods
kubectl get pods -n monitoring

# Live app test
curl -s https://gregddevops.com.ng/api/customer/owners | jq length
curl -I https://gregddevops.com.ng
```

**Expected final state:**

| Layer | Status |
|---|---|
| Nodes | 2× m7i-flex.large — Ready |
| Petclinic | 8/8 pods 1/1 Running |
| ArgoCD | 8/8 apps Synced + Healthy |
| Monitoring | 7/7 pods Running — 21 Prometheus targets, 28 Grafana dashboards |
| Ingress | ALB provisioned, gregddevops.com.ng → ALB alias |
| TLS | ACM cert ISSUED, HTTP→HTTPS redirect active |
| Secrets | ESO syncing db-secret + openai-secret |
| Git | dev branch clean, pushed to petclinic-platform |

---

## Challenges & Solutions

### Challenge 1 — ESO ClusterSecretStore Wrong Region
**Problem:** `ClusterSecretStore` was configured for `us-east-1` but referenced `af-south-1` region causing ESO to fail fetching secrets.
**Solution:** Updated `k8s/external-secrets/secret-store.yaml` to use `us-east-1` and recreated the ExternalSecrets to force reconciliation.

---

### Challenge 2 — t3.small Pod Limit (Too Many Pods)
**Problem:** EKS `t3.small` nodes have a hard limit of 11 pods per node. With system pods consuming slots, only 5-6 slots remained per node — not enough for 8 services.

**Error:**
```
0/2 nodes are available: 2 Too many pods
```

**Solution:** Created a new node group using `m7i-flex.large` instances (Free Tier eligible, 29 pods per node, 8GB RAM).

```bash
aws eks create-nodegroup \
  --cluster-name petclinic-eks \
  --nodegroup-name petclinic-eks-large \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --instance-types m7i-flex.large \
  ...
aws eks delete-nodegroup \
  --cluster-name petclinic-eks \
  --nodegroup-name petclinic-eks-nodes \
  --region us-east-1
```

---

### Challenge 3 — NotReady Nodes After Scale-Up
**Problem:** After scaling to 5 nodes, 3 new nodes came up `NotReady` with taint `node.kubernetes.io/unreachable`. Pods couldn't schedule anywhere.

**Solution:** Deleted all 4 bad nodes from kubectl — EKS node group automatically replaces deleted nodes with fresh healthy ones.

```bash
kubectl delete node \
  ip-10-0-1-35.ec2.internal \
  ip-10-0-1-36.ec2.internal \
  ip-10-0-2-33.ec2.internal \
  ip-10-0-2-220.ec2.internal
```

---

### Challenge 4 — t3.medium Not Free Tier Eligible
**Problem:** Attempted to create `t3.medium` node group but AWS rejected it:
```
InvalidParameterCombination - The specified instance type is not 
eligible for Free Tier
```

**Solution:** Queried Free Tier eligible instance types and found `m7i-flex.large` (8GB RAM, Free Tier eligible in us-east-1).

```bash
aws ec2 describe-instance-types \
  --filters "Name=free-tier-eligible,Values=true" \
  --query 'InstanceTypes[*].{type: InstanceType, memoryMiB: MemoryInfo.SizeInMiB}' \
  --region us-east-1 --output table
```

---

### Challenge 5 — Git History Diverged After Rebase Abort
**Problem:** After aborting the rebase, local `dev` branch had diverged from `origin/dev`. Direct push was rejected (non-fast-forward).

**Solution:** Reset local dev to match `origin/dev` exactly, then cherry-picked only the 4-file fix commit on top.

```bash
git fetch origin dev
git reset --hard origin/dev
git cherry-pick 78a1a46   # only the 4-file fix commit
git push origin dev
```

---

### Challenge 6 — RDS Endpoint Still af-south-1 in Helm Values
**Problem:** `helm-values/customers-service.yaml`, `vets-service.yaml`, `visits-service.yaml` still had the old `af-south-1` RDS endpoint causing pods to crashloop.

**Solution:** Updated all 3 files with `sed` then redeployed via Helm.

```bash
sed -i 's|petclinic-dev-mysql.cp6ymios4vqr.af-south-1.rds.amazonaws.com|petclinic-mysql.co38siyqqwll.us-east-1.rds.amazonaws.com|g' \
  helm-values/customers-service.yaml \
  helm-values/vets-service.yaml \
  helm-values/visits-service.yaml
```

---

### Challenge 7 — Grafana Port Conflict
**Problem:** Local port 3000 was already in use by another Grafana instance.
**Solution:** Port-forwarded to 3002 instead.

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3002:80
```

---

## Access Points

| Service | URL | Credentials |
|---|---|---|
| PetClinic App | https://gregddevops.com.ng | Public |
| ArgoCD UI | http://ab0c6a7cb31114136811e3770ab7a7d6-1941241676.us-east-1.elb.amazonaws.com | admin / VCnLcyGY7MB09Xds |
| Grafana | http://localhost:3002 (port-forward) | admin / admin123 |
| Prometheus | http://localhost:9090 (port-forward) | None |

---

## Cost Management

### Stop Environment (save money overnight)
```bash
# Scale nodes to 0
aws eks update-nodegroup-config \
  --cluster-name petclinic-eks \
  --nodegroup-name petclinic-eks-large \
  --scaling-config minSize=0,maxSize=3,desiredSize=0 \
  --region us-east-1

# Stop RDS
aws rds stop-db-instance \
  --db-instance-identifier petclinic-mysql \
  --region us-east-1
```

### Start Environment
```bash
# Start RDS
aws rds start-db-instance \
  --db-instance-identifier petclinic-mysql \
  --region us-east-1

# Scale nodes back up
aws eks update-nodegroup-config \
  --cluster-name petclinic-eks \
  --nodegroup-name petclinic-eks-large \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --region us-east-1

# Reconnect kubectl
aws eks update-kubeconfig --region us-east-1 --name petclinic-eks
```

---

## CI/CD — Triggering a Build

### Trigger a Build via GitHub Actions

The CI pipeline lives in `Achievers11-DevOps/petclinic-app` and triggers on push to `main`.

**Option 1 — Push a code change:**
```bash
cd ~/Petclinic-Platform-G11/petclinic-app
# Make any change
echo "# trigger" >> README.md
git add README.md
git commit -m "trigger: rebuild all images"
git push origin main
```

**Option 2 — Trigger manually via GitHub UI:**
1. Go to `https://github.com/Achievers11-DevOps/petclinic-app/actions`
2. Click the CI workflow
3. Click **Run workflow** → select `main` branch → click **Run workflow**

**Option 3 — Trigger via GitHub CLI:**
```bash
gh workflow run ci.yml \
  --repo Achievers11-DevOps/petclinic-app \
  --ref main
```

### What the CI Pipeline Does
1. Checkout source code
2. Set up Java 17
3. Configure AWS credentials
4. Login to ECR (`us-east-1`)
5. Build all 8 Docker images with Maven
6. Tag images with Git SHA
7. Push all 8 images to ECR
8. Clone `petclinic-platform` repo
9. Update image tag in `helm-values/dev.yaml`
10. Commit and push to `petclinic-platform` dev branch
11. ArgoCD detects the change and auto-deploys

### Verify a Successful Build
```bash
# Check latest image tags in ECR
for SERVICE in config-server discovery-server api-gateway \
  customers-service vets-service visits-service \
  genai-service admin-server; do
  TAG=$(aws ecr describe-images \
    --repository-name petclinic/$SERVICE \
    --region us-east-1 \
    --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
    --output text)
  echo "$SERVICE: $TAG"
done

# Check ArgoCD has picked up new image
kubectl get applications -n argocd

# Check pods are on new image
kubectl describe pod -n petclinic -l app.kubernetes.io/name=api-gateway | grep Image:
```

---

## Key Infrastructure Details

| Resource | Name/Value |
|---|---|
| EKS Cluster | petclinic-eks |
| Node Group | petclinic-eks-large (m7i-flex.large) |
| RDS Endpoint | petclinic-mysql.co38siyqqwll.us-east-1.rds.amazonaws.com |
| ACM Cert ARN | arn:aws:acm:us-east-1:118821711881:certificate/3fddd3a5-1f3a-4633-bf41-ceb61d492879 |
| ALB Hosted Zone (us-east-1) | Z35SXDOTRQ7X7K |
| Route 53 Zone ID | Z10395433FWC00PFCKRCW |
| ESO Role ARN | arn:aws:iam::118821711881:role/petclinic-eso-role |
| EKS Node Role | arn:aws:iam::118821711881:role/petclinic-eks-node-role |

---

*Generated: May 15, 2026 | Project D — Achievers11-DevOps G11*
