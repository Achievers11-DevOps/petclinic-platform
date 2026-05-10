# 🐾 Spring PetClinic Microservices — Full DevOps Project on AWS EKS

> **A complete, production-grade DevOps project** by **Greg Odi** — deploying the Spring PetClinic Microservices application on AWS EKS with CI/CD, GitOps, Monitoring, Distributed Tracing, and an AI-powered GenAI chat feature.

---

## 📸 Project Evidence Screenshots

### 🌐 Live Application on AWS
![App Live](screenshots/evidence_of_App.png)
*Spring PetClinic running publicly on AWS ALB with GenAI Chat feature*

### 🔄 ArgoCD GitOps — Healthy & Synced
![ArgoCD](screenshots/evidence_ARGOCD.png)
*ArgoCD automatically syncing deployments from GitHub to EKS*

### 📊 Grafana — Kubernetes Cluster Metrics
![Grafana Cluster](screenshots/grafana_cluster_metrics.png)
*Real-time CPU (4.88%) and Memory (92.5%) metrics across the EKS cluster*

### 📈 Grafana — With Live Metrics
![Grafana Metrics](screenshots/grafana_with_metrics.png)
*Grafana dashboards showing live Kubernetes namespace metrics*

### 🔥 Prometheus — Targets All UP
![Prometheus](screenshots/evidence_of_prometheus.png)
*Prometheus scraping metrics from all Kubernetes components*

### 🔍 Prometheus — Target Health Detail
![Prometheus Targets](screenshots/prometheus_targets.png)
*All Prometheus targets showing UP state*

### 🔎 Zipkin — Distributed Tracing
![Zipkin](screenshots/evidence_of_Zipkin.png)
*Zipkin tracing requests across all microservices*

### ✅ GitHub Actions — CI/CD Pipeline Green
![CI/CD Green](screenshots/github_actions_green.png)
*Both build-and-push (4m 42s) and update-image-tags (6s) jobs passing*

### 🐳 Build and Push to ECR
![Build Push ECR](screenshots/build_push_ecr.png)
*Docker images built and pushed to Amazon ECR*

### 📦 ECR Images Pushed
![ECR Images](screenshots/ecr_images_pushed.png)
*All 8 service images stored in Amazon ECR*

### 🖥️ EKS All Pods Running
![All Pods Running](screenshots/all_pods_running.png)
*All microservice pods running successfully in petclinic-dev namespace*

### 🔑 AWS Secrets Manager
![Secrets Manager](screenshots/aws_secrets_manager.png)
*Secrets securely stored in AWS Secrets Manager*

### 🔐 OIDC IAM Role Created
![OIDC IAM](screenshots/oidc_iam_role.png)
*GitHub Actions OIDC IAM role for keyless AWS authentication*

### 🔒 AWS Role ARN Secret Added
![AWS Role ARN](screenshots/aws_role_arn.png)
*AWS Role ARN secret configured in GitHub organization*

### 📋 GitHub Org Secrets Complete
![Org Secrets](screenshots/org_secrets_complete.png)
*All required secrets configured in GitHub organization*

### 🗄️ RDS Endpoint Confirmed
![RDS Endpoint](screenshots/rds_endpoint.png)
*Amazon RDS MySQL endpoint confirmed and accessible*

### 🔓 OpenAI Secret Updated
![OpenAI Secret](screenshots/openai_secret.png)
*OpenAI API key securely stored for GenAI service*

### 🌿 Git Branches Created
![Branches](screenshots/branches_created.png)
*Feature branches created following GitFlow workflow*

### 📤 Git Commit Pushed
![Git Commit](screenshots/git_commit_pushed.png)
*Code committed and pushed following Jira ticket naming convention*

### 📝 Helm Values Created
![Helm Values](screenshots/helm_values_created.png)
*Helm values files created for each microservice*

### 🔗 External Secrets Synced
![External Secrets](screenshots/external_secrets_synced.png)
*External Secrets Operator syncing secrets from AWS Secrets Manager*

### 🏪 Cluster Secret Store Ready
![Cluster Secret Store](screenshots/cluster_secret_store.png)
*ClusterSecretStore configured and ready*

### 🔀 Pull Request Opened
![PR Opened](screenshots/pr_opened.png)
*Pull request opened following GitFlow review process*

### 📊 Phase C Summary
![Phase C Summary](screenshots/phase_c_summary.png)
*Summary of Phase C completion*

### 🖼️ ECR Images Local
![ECR Local](screenshots/ecr_images_local.png)
*Docker images verified locally before pushing to ECR*

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Architecture](#-architecture)
3. [Technology Stack](#-technology-stack)
4. [Prerequisites](#-prerequisites)
5. [Phase A — Tools Installation](#phase-a--tools-installation)
6. [Phase B — AWS Setup](#phase-b--aws-setup)
7. [Phase C — EKS Cluster](#phase-c--eks-cluster)
8. [Phase D — RDS MySQL Database](#phase-d--rds-mysql-database)
9. [Phase E — ECR Repositories](#phase-e--ecr-repositories)
10. [Phase F — GitHub Actions CI/CD](#phase-f--github-actions-cicd)
11. [Phase G — ArgoCD GitOps](#phase-g--argocd-gitops)
12. [Phase H — ALB Ingress](#phase-h--alb-ingress)
13. [Phase I — Monitoring Stack](#phase-i--monitoring-stack)
14. [All URLs and Credentials](#-all-urls-and-credentials)
15. [Session Start Commands](#-session-start---run-every-time)
16. [Cost Management](#-cost-management)
17. [Troubleshooting](#-troubleshooting)

---

## 🎯 Project Overview

This project deploys the **Spring PetClinic Microservices** application — a veterinary clinic management system — using a complete DevOps pipeline on AWS. Every commit to the main branch automatically:

1. Builds Docker images from the Spring PetClinic source
2. Pushes images to AWS ECR (Elastic Container Registry)
3. Updates image tags in the GitOps platform repository
4. ArgoCD detects the change and deploys to Kubernetes automatically

### What the Application Does
- 🏠 **Manage pet owners** — add, search, and update owner records
- 🐾 **Manage pets** — register pets with their owners
- 🏥 **Manage visits** — schedule and track vet visits
- 👨‍⚕️ **View veterinarians** — see available vets and specialities
- 🤖 **AI Chat** — ask questions about pet care powered by OpenAI GPT

### Repositories
| Repository | Purpose |
|-----------|---------|
| `Achievers11-DevOps/petclinic-app` | Application source code + CI/CD workflows |
| `Achievers11-DevOps/petclinic-platform` | Helm values + Kubernetes manifests (GitOps) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPER WORKFLOW                         │
│                                                               │
│  git push → GitHub → GitHub Actions → ECR → ArgoCD → EKS    │
└─────────────────────────────────────────────────────────────┘

Detailed Flow:

Developer pushes code
        │
        ▼
┌─────────────────┐
│  GitHub Actions  │  ← Triggered on every push to main
│  build-push.yml  │
│                  │
│  1. Pull images  │
│  2. Push to ECR  │
│  3. Update tags  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   AWS ECR        │  ← Docker image storage
│  8 repositories  │     Region: af-south-1
│  petclinic-dev/  │
└────────┬────────┘
         │ image tag written to
         ▼
┌──────────────────────┐
│ petclinic-platform   │  ← GitOps source of truth
│  (GitHub repo)        │
│  helm-values/         │
│  ├─ config-server     │
│  ├─ api-gateway       │
│  └─ ...etc            │
└────────┬─────────────┘
         │ ArgoCD polls every 3 min
         ▼
┌─────────────────────────────────────────────────────┐
│                 AWS EKS Cluster                       │
│                 petclinic-dev                         │
│                 af-south-1 (Cape Town)                │
│  ┌────────────────────────────────────────────────┐  │
│  │          petclinic-dev namespace                │  │
│  │                                                 │  │
│  │  [1] config-server      :8888  ← starts FIRST  │  │
│  │  [2] discovery-server   :8761  ← starts SECOND │  │
│  │  [3] api-gateway        :8080  ← public entry  │  │
│  │  [4] customers-service  :8081                  │  │
│  │  [5] vets-service       :8083                  │  │
│  │  [6] visits-service     :8082                  │  │
│  │  [7] genai-service      :8084                  │  │
│  │  [8] admin-server       :9090                  │  │
│  │  [9] zipkin             :9411  ← tracing       │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │          monitoring namespace                   │  │
│  │  prometheus  grafana  alertmanager              │  │
│  └────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────┐  │
│  │          argocd namespace                       │  │
│  │  argocd-server  argocd-repo-server              │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│  AWS ALB     │    │  AWS RDS MySQL   │
│  (public)    │    │  petclinic-dev   │
└──────────────┘    └──────────────────┘
```

---

## 🛠️ Technology Stack

| Category | Technology | Version |
|----------|-----------|---------|
| **Cloud Provider** | AWS | — |
| **Region** | af-south-1 (Cape Town) | — |
| **Container Orchestration** | Amazon EKS | 1.32 |
| **Worker Nodes** | EC2 t3.medium | 3-4 nodes |
| **Container Registry** | Amazon ECR | — |
| **Database** | Amazon RDS MySQL | 8.0 |
| **CI/CD** | GitHub Actions | — |
| **GitOps** | ArgoCD | v3.4.1 |
| **Ingress Controller** | AWS Load Balancer Controller | — |
| **Load Balancer** | AWS ALB | — |
| **Metrics** | Prometheus | kube-prom-stack |
| **Dashboards** | Grafana | kube-prom-stack |
| **Distributed Tracing** | Zipkin | latest |
| **Secret Management** | AWS Secrets Manager + ESO | — |
| **IaC** | Terraform | — |
| **Package Manager** | Helm | v3 |
| **Application Framework** | Spring Boot | 3.x |
| **Language** | Java | 17 |
| **AI Model** | OpenAI GPT-4o-mini | — |

---

## ✅ Prerequisites

| Requirement | Why |
|-------------|-----|
| AWS Account with admin IAM user | Provision all cloud resources |
| GitHub account | Store code and run CI/CD |
| Ubuntu 22.04 machine (or WSL2) | Run CLI tools |
| 8GB RAM minimum | Run Docker builds |
| Basic Linux command line knowledge | Execute all commands |

---

## Phase A — Tools Installation

Install every tool needed for this project on Ubuntu 22.04.

### Step 1 — Update Your System
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2 — Install AWS CLI v2
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version
# Expected: aws-cli/2.x.x
```

### Step 3 — Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
# Expected: Client Version: v1.32.x
```

### Step 4 — Install eksctl
```bash
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

### Step 5 — Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### Step 6 — Install Docker
```bash
sudo apt install docker.io -y
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

### Step 7 — Install Terraform
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform --version
```

### Step 8 — Install Git
```bash
sudo apt install git -y
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git --version
```

### ✅ Verify All Tools
```bash
echo "=== All Tools ===" && \
aws --version && \
kubectl version --client --short && \
eksctl version && \
helm version --short && \
docker --version && \
terraform --version && \
git --version
```

---

## Phase B — AWS Setup

### Step 1 — Configure AWS CLI
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region=af-south-1, format=json
```

### Step 2 — Verify Your Account
```bash
aws sts get-caller-identity
```
Expected:
```json
{
    "UserId": "AIDXXXXXXXXXXXXXXXXXX",
    "Account": "118821711881",
    "Arn": "arn:aws:iam::118821711881:user/petclinic-admin"
}
```

### Step 3 — Create GitHub OIDC Provider
Allows GitHub Actions to authenticate with AWS without storing credentials:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 4 — Create IAM Role for GitHub Actions
```bash
cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::118821711881:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Achievers11-DevOps/petclinic-app:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name petclinic-github-actions-role \
  --assume-role-policy-document file:///tmp/trust-policy.json

aws iam attach-role-policy \
  --role-name petclinic-github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-role-policy \
  --role-name petclinic-github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Get the Role ARN
aws iam get-role --role-name petclinic-github-actions-role \
  --query 'Role.Arn' --output text
```

### Step 5 — Store OpenAI Key in Secrets Manager
```bash
aws secretsmanager create-secret \
  --name petclinic/openai-api-key \
  --secret-string "sk-your-openai-key" \
  --region af-south-1
```

---

## Phase C — EKS Cluster

### Step 1 — Create the Cluster
```bash
eksctl create cluster \
  --name petclinic-dev \
  --region af-south-1 \
  --nodegroup-name petclinic-dev-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed
```
> ⏱️ Takes 15-20 minutes. You will see CloudFormation stacks being created.

### Step 2 — Connect kubectl
```bash
aws eks update-kubeconfig --region af-south-1 --name petclinic-dev
kubectl get nodes
```
Expected — all nodes showing `Ready`:
```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-1-87.af-south-1.compute.internal    Ready    <none>   5m    v1.32.13-eks-4136f65
ip-10-0-2-100.af-south-1.compute.internal   Ready    <none>   5m    v1.32.13-eks-4136f65
ip-10-0-1-236.af-south-1.compute.internal   Ready    <none>   5m    v1.32.13-eks-4136f65
```

### Step 3 — Create Namespace
```bash
kubectl create namespace petclinic-dev
```

---

## Phase D — RDS MySQL Database

### Step 1 — Create RDS Instance
```bash
aws rds create-db-instance \
  --db-instance-identifier petclinic-dev-mysql \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --master-username petclinic \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --region af-south-1
```
> ⏱️ Takes 5-10 minutes.

### Step 2 — Get RDS Endpoint
```bash
aws rds describe-db-instances \
  --db-instance-identifier petclinic-dev-mysql \
  --region af-south-1 \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```
Example: `petclinic-dev-mysql.cp6ymios4vqr.af-south-1.rds.amazonaws.com`

### Step 3 — Create Kubernetes Secret
```bash
kubectl create secret generic petclinic-db-secret \
  --from-literal=username=petclinic \
  --from-literal=password=YourSecurePassword123! \
  -n petclinic-dev
```

---

## Phase E — ECR Repositories

### Step 1 — Create Repositories
```bash
for SERVICE in config-server discovery-server api-gateway \
               customers-service vets-service visits-service \
               genai-service admin-server; do
  aws ecr create-repository \
    --repository-name petclinic-dev/$SERVICE \
    --region af-south-1
  echo "✅ Created: petclinic-dev/$SERVICE"
done
```

### Step 2 — Verify
```bash
aws ecr describe-repositories \
  --region af-south-1 \
  --query 'repositories[].repositoryName' \
  --output table
```

---

## Phase F — GitHub Actions CI/CD

### Step 1 — Add GitHub Organization Secrets
Go to: `GitHub Organization → Settings → Secrets and variables → Actions`

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCOUNT_ID` | `118821711881` |
| `AWS_REGION` | `af-south-1` |
| `AWS_ROLE_ARN` | `arn:aws:iam::118821711881:role/petclinic-github-actions-role` |
| `PLATFORM_REPO_PAT` | GitHub Personal Access Token with repo write access |
| `OPENAI_API_KEY` | Your OpenAI API key |

### Step 2 — Create Platform Repo helm-values
```bash
cd petclinic-platform
mkdir -p helm-values

for SERVICE in config-server discovery-server api-gateway \
               customers-service vets-service visits-service \
               genai-service admin-server; do
cat > helm-values/${SERVICE}.yaml << EOF
image:
  repository: 118821711881.dkr.ecr.af-south-1.amazonaws.com/petclinic-dev/${SERVICE}
  tag: "latest"
  pullPolicy: Always
EOF
done

git add helm-values/
git commit -m "feat: add helm-values for all services"
git push origin main
```

### Step 3 — Create CI/CD Workflow
Create `.github/workflows/build-push.yml` in `petclinic-app`:

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [main]

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    outputs:
      image_tag: ${{ steps.set-tag.outputs.tag }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2

      - name: Set image tag
        id: set-tag
        run: echo "tag=${GITHUB_SHA::7}" >> $GITHUB_OUTPUT

      - name: Pull, tag and push all images to ECR
        run: |
          SHA="${{ steps.set-tag.outputs.tag }}"
          ECR_REGISTRY=${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com

          for SERVICE in config-server discovery-server api-gateway \
            customers-service vets-service visits-service \
            genai-service admin-server; do
            docker pull springcommunity/spring-petclinic-$SERVICE:latest
            docker tag springcommunity/spring-petclinic-$SERVICE:latest \
              $ECR_REGISTRY/petclinic-dev/$SERVICE:$SHA
            docker tag springcommunity/spring-petclinic-$SERVICE:latest \
              $ECR_REGISTRY/petclinic-dev/$SERVICE:latest
            docker push $ECR_REGISTRY/petclinic-dev/$SERVICE:$SHA
            docker push $ECR_REGISTRY/petclinic-dev/$SERVICE:latest
            echo "✅ Pushed: $SERVICE:$SHA"
          done

  update-image-tags:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Checkout platform repo
        uses: actions/checkout@v4
        with:
          repository: Achievers11-DevOps/petclinic-platform
          token: ${{ secrets.PLATFORM_REPO_PAT }}
          ref: main
          path: petclinic-platform

      - name: Update image tags and push
        working-directory: petclinic-platform
        run: |
          SHA="${{ needs.build-and-push.outputs.image_tag }}"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          for SERVICE in config-server discovery-server api-gateway \
                         customers-service vets-service visits-service \
                         genai-service admin-server; do
            FILE="helm-values/${SERVICE}.yaml"
            if [ -f "$FILE" ]; then
              sed -i "s/tag: .*/tag: \"${SHA}\"/" "$FILE"
              echo "✅ Updated $SERVICE → $SHA"
            fi
          done

          git add helm-values/
          if git diff --staged --quiet; then
            echo "No changes to commit"
          else
            git commit -m "ci: update image tags to ${SHA}"
            git push origin main
          fi
```

### Step 4 — Trigger and Verify
```bash
git add .github/workflows/build-push.yml
git commit -m "ci: add build-push workflow"
git push origin main
```
Go to GitHub Actions — both jobs should show ✅ green.

---

## Phase G — ArgoCD GitOps

### Step 1 — Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2 — Wait for Pods
```bash
kubectl get pods -n argocd -w
# Wait until all show 1/1 Running, then Ctrl+C
```

### Step 3 — Get Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
# SAVE THIS PASSWORD!
```

### Step 4 — Expose ArgoCD UI
```bash
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'
sleep 60
kubectl get svc argocd-server -n argocd
# Copy the EXTERNAL-IP
```

### Step 5 — Create ArgoCD Application
```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: petclinic
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Achievers11-DevOps/petclinic-platform
    targetRevision: main
    path: helm-values
  destination:
    server: https://kubernetes.default.svc
    namespace: petclinic-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Step 6 — Verify
```bash
kubectl get applications -n argocd
# Expected: petclinic   Synced   Healthy
```

---

## Phase H — ALB Ingress

### Step 1 — Create IRSA Service Account
```bash
curl -o /tmp/alb-iam-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/alb-iam-policy.json

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

eksctl create iamserviceaccount \
  --cluster=petclinic-dev \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region af-south-1 \
  --approve
```

### Step 2 — Install Load Balancer Controller
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster \
  --name petclinic-dev --region af-south-1 \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=petclinic-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=af-south-1 \
  --set vpcId=$VPC_ID

# Verify both pods Running
kubectl get pods -n kube-system | grep aws-load-balancer
```

### Step 3 — Create Ingress
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petclinic-ingress
  namespace: petclinic-dev
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
EOF

# Wait 3 min for ALB to provision
sleep 180
kubectl get ingress petclinic-ingress -n petclinic-dev
```

---

## Phase I — Monitoring Stack

### Step 1 — Scale to 4 Nodes First
```bash
aws eks update-nodegroup-config \
  --cluster-name petclinic-dev \
  --nodegroup-name petclinic-dev-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=4 \
  --region af-south-1

kubectl get nodes -w
# Wait until 4 nodes show Ready, then Ctrl+C
```

### Step 2 — Install Prometheus + Grafana
```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set grafana.adminPassword=PetClinic@2026 \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheusOperator.admissionWebhooks.enabled=false \
  --set prometheusOperator.admissionWebhooks.patch.enabled=false \
  --set prometheusOperator.tls.enabled=false

kubectl get pods -n monitoring -w
# Wait until all Running, then Ctrl+C
```

### Step 3 — Install Zipkin
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: petclinic-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  namespace: petclinic-dev
spec:
  type: LoadBalancer
  selector:
    app: zipkin
  ports:
  - port: 9411
    targetPort: 9411
EOF
```

### Step 4 — Access via Port-Forward
```bash
# Grafana (use 3001 if 3000 is busy on your machine)
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring

# Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9091:9090 -n monitoring

# Zipkin
kubectl port-forward svc/zipkin 9411:9411 -n petclinic-dev
```

Open Grafana at `http://localhost:3001`
- Username: `admin`
- Password: `PetClinic@2026`

Go to **Dashboards → Kubernetes / Compute Resources / Cluster** to see live metrics.

---

## 🌐 All URLs and Credentials

### Public URLs
| Service | URL |
|---------|-----|
| **🌐 Application** | `http://k8s-petclini-petclini-00eca135a7-1242331605.af-south-1.elb.amazonaws.com` |
| **🔄 ArgoCD** | `https://a60a61fc4968b45788dd714523be7df3-39386741.af-south-1.elb.amazonaws.com` |

### Port-Forward URLs
| Service | Command | URL |
|---------|---------|-----|
| **📊 Grafana** | `kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring` | `http://localhost:3001` |
| **🔥 Prometheus** | `kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9091:9090 -n monitoring` | `http://localhost:9091` |
| **🔍 Zipkin** | `kubectl port-forward svc/zipkin 9411:9411 -n petclinic-dev` | `http://localhost:9411` |

### Credentials
| Service | Username | Password |
|---------|----------|---------|
| ArgoCD | `admin` | Run: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Grafana | `admin` | `PetClinic@2026` |

---

## 🔄 Session Start — Run Every Time

```bash
# Reconnect kubectl
aws eks update-kubeconfig --region af-south-1 --name petclinic-dev

# Verify cluster
kubectl get nodes
kubectl get pods -n petclinic-dev

# Start port-forwards
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring &
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9091:9090 -n monitoring &
kubectl port-forward svc/zipkin 9411:9411 -n petclinic-dev &

echo "✅ Ready!"
```

---

## 💰 Cost Management

| Resource | Cost |
|----------|------|
| EKS Control Plane | ~$0.10/hour |
| 4x t3.medium nodes | ~$0.17/hour each |
| RDS t3.micro | ~$0.02/hour |
| ALB | ~$0.02/hour |
| **Total** | ~$0.50/hour (~$12/day) |

### Scale Down (Save Money)
```bash
aws eks update-nodegroup-config \
  --cluster-name petclinic-dev \
  --nodegroup-name petclinic-dev-nodes \
  --scaling-config minSize=0,maxSize=5,desiredSize=0 \
  --region af-south-1
```

### Scale Back Up
```bash
aws eks update-nodegroup-config \
  --cluster-name petclinic-dev \
  --nodegroup-name petclinic-dev-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=3 \
  --region af-south-1
aws eks update-kubeconfig --region af-south-1 --name petclinic-dev
```

### What Survives Deletion
- ✅ ECR images
- ✅ RDS database
- ✅ GitHub repositories
- ✅ Jira tickets
- ✅ IAM roles and policies
- ✅ Secrets Manager entries

---

## 🔧 Troubleshooting

### kubectl Not Connecting
```bash
aws eks update-kubeconfig --region af-south-1 --name petclinic-dev
```

### Pods in CrashLoopBackOff
```bash
kubectl logs <pod-name> -n petclinic-dev --tail=50
kubectl describe pod <pod-name> -n petclinic-dev | grep -A15 "Events:"
kubectl rollout restart deployment <service-name> -n petclinic-dev
```

### Pods Pending — Too Many Pods
```bash
# Scale up nodes
aws eks update-nodegroup-config \
  --cluster-name petclinic-dev \
  --nodegroup-name petclinic-dev-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=4 \
  --region af-south-1
```

### GitHub Actions Failing
| Error | Fix |
|-------|-----|
| `sts:AssumeRoleWithWebIdentity denied` | Check trust policy repo name |
| `ECR repository not found` | Re-run Phase E |
| `helm-values/ not found` | Ensure platform repo main branch has the folder |
| `working-directory not found` | Add `path: petclinic-platform` to checkout step |

### ALB Ingress No Address
```bash
# Check LBC logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=20

# Update IAM policy to latest
curl -o /tmp/alb-iam-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy-version \
  --policy-arn arn:aws:iam::118821711881:policy/AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/alb-iam-policy.json \
  --set-as-default
```

### Grafana No Data
1. Open `http://localhost:9091/targets`
2. All targets must show `UP`
3. If DOWN: `kubectl get pods -n monitoring`

---

## 📁 Repository Structure

```
petclinic-app/ (Application Repository)
├── .github/
│   └── workflows/
│       └── build-push.yml          # CI/CD pipeline
├── spring-petclinic-config-server/
├── spring-petclinic-discovery-server/
├── spring-petclinic-api-gateway/
├── spring-petclinic-customers-service/
├── spring-petclinic-vets-service/
├── spring-petclinic-visits-service/
├── spring-petclinic-genai-service/
├── spring-petclinic-admin-server/
└── docker-compose.yml

petclinic-platform/ (GitOps Repository)
├── helm-values/                    # ArgoCD watches this
│   ├── config-server.yaml
│   ├── discovery-server.yaml
│   ├── api-gateway.yaml
│   ├── customers-service.yaml
│   ├── vets-service.yaml
│   ├── visits-service.yaml
│   ├── genai-service.yaml
│   └── admin-server.yaml
├── helm/petclinic-service/         # Helm chart
├── k8s/external-secrets/           # ESO manifests
├── terraform/                      # Infrastructure as Code
└── scripts/                        # Helper scripts
```

---

## 📚 References

- [Spring PetClinic Microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Zipkin](https://zipkin.io/)

---

*Built with ❤️ by **Greg Odi** solely of the **Achievers11 DevOps Team** — May 2026*

*AWS Region: af-south-1 (Cape Town, South Africa) 🇿🇦*
