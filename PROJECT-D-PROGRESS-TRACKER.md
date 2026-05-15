# Project D — Progress Tracker
## Spring PetClinic Microservices (us-east-1 Deployment)
## Last Updated: May 15, 2026

---

## Identity
| Item | Value |
|---|---|
| AWS Account ID | 118821711881 |
| Region | us-east-1 |
| Cluster | petclinic-eks |
| Namespace | petclinic |
| ECR Registry | 118821711881.dkr.ecr.us-east-1.amazonaws.com |
| Domain | gregddevops.com.ng |
| Route 53 Zone | Z10395433FWC00PFCKRCW |
| Working Dir | ~/Petclinic-Platform-G11/petclinic-platform |
| Platform Repo | Achievers11-DevOps/petclinic-platform (dev branch) |

---

## 13-Phase Deployment Status

| Phase | Task | Status |
|---|---|---|
| Pre-flight | Fix variables.tf/backend.tf region → us-east-1 | ✅ DONE |
| Phase 1 | Terraform apply (VPC, EKS, RDS, ECR) | ✅ DONE |
| Phase 2 | Namespaces (petclinic, argocd, monitoring) | ✅ DONE |
| Phase 3 | AWS Load Balancer Controller | ✅ DONE |
| Phase 4 | External Secrets Operator + ClusterSecretStore | ✅ DONE |
| Phase 5 | Secrets Manager (DB credentials + OpenAI key) | ✅ DONE |
| Phase 6 | ECR pull secret in cluster | ✅ DONE |
| Phase 7 | Copy images af-south-1 → us-east-1 via crane | ✅ DONE |
| Phase 8 | Helm deploy all 8 services | ✅ DONE |
| Phase 9 | ArgoCD install + ApplicationSet | ✅ DONE |
| Phase 10 | Ingress + HTTPS + Route 53 → ALB | ✅ DONE |
| Phase 11 | Monitoring (kube-prometheus-stack / Grafana) | ✅ DONE |
| Phase 12 | Commit everything to dev branch | ✅ DONE |
| Phase 13 | Final verification across all namespaces | ✅ DONE |

---

## ECR Status

| Registry | Repos | Status |
|---|---|---|
| af-south-1 (source) | petclinic-dev/{service}:latest | ✅ All 8 images exist |
| us-east-1 (target) | petclinic/{service} | ✅ All 8 repos created, ❌ no images yet |

### 8 Services to Copy
```
config-server
discovery-server
api-gateway
customers-service
vets-service
visits-service
genai-service
admin-server
```

---

## ❌ Where We Stopped — Phase 7 (crane not installed)

### After laptop restart, run these commands in order:

#### Step 1 — Reconnect kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-eks
kubectl get pods -n petclinic
```

#### Step 2 — Install crane
```bash
curl -sL "https://github.com/google/go-containerregistry/releases/download/v0.19.1/go-containerregistry_Linux_x86_64.tar.gz" | tar -xz crane
sudo mv crane /usr/local/bin/crane
crane version
```

#### Step 3 — Authenticate crane to both ECR regions
```bash
# Source: af-south-1
aws ecr get-login-password --region af-south-1 | \
  crane auth login \
  118821711881.dkr.ecr.af-south-1.amazonaws.com \
  --username AWS --password-stdin

# Target: us-east-1
aws ecr get-login-password --region us-east-1 | \
  crane auth login \
  118821711881.dkr.ecr.us-east-1.amazonaws.com \
  --username AWS --password-stdin
```

#### Step 4 — Copy all 8 images from af-south-1 → us-east-1
```bash
for SERVICE in config-server discovery-server api-gateway \
  customers-service vets-service visits-service \
  genai-service admin-server; do
  echo "⏳ Copying $SERVICE..."
  crane copy \
    118821711881.dkr.ecr.af-south-1.amazonaws.com/petclinic-dev/$SERVICE:latest \
    118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic/$SERVICE:latest
  echo "✅ $SERVICE done"
done
```

#### Step 5 — Verify all images landed in us-east-1
```bash
for SERVICE in config-server discovery-server api-gateway \
  customers-service vets-service visits-service \
  genai-service admin-server; do
  echo "Checking $SERVICE..."
  aws ecr list-images \
    --repository-name petclinic/$SERVICE \
    --region us-east-1 \
    --query 'imageIds[*].imageTag' \
    --output text
done
```

---

## Important Notes

### Rebase Warning
- `petclinic-platform` repo has a rebase IN PROGRESS on `dev` branch
- **DO NOT touch the rebase** — leave it as-is to avoid data loss
- Conflicts exist in:
  - `k8s/external-secrets/openai-secret.yaml`
  - `k8s/external-secrets/secret-store.yaml`

### Cost Reminder
- EKS `petclinic-eks` is running in us-east-1 — costs ~$0.10/hr
- Delete after each session if not actively using:
  ```bash
  eksctl delete cluster --name petclinic-eks --region us-east-1
  ```

### Previous Projects
| Project | Cluster | Region | Status |
|---|---|---|---|
| Project 1 (Solo) | petclinic-cluster | af-south-1 | ✅ Complete, deleted |
| Project 2 (Team platform) | petclinic-dev | af-south-1 | ✅ Complete |
| Project 3 (Team C) | petclinic-eks (Achievers11) | us-east-1 | ✅ PRs raised |
| Project D (This) | petclinic-eks | us-east-1 | 🔄 Phase 7 in progress |

---

## Session Restart Phrase
When returning to Claude, say:
> "I'm back — continuing Project D Phase 7"
