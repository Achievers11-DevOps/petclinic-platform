# PetClinic Full Deployment Prompt

Paste everything below this line into Claude Code to run all 13 deployment phases.

---

You are deploying Spring PetClinic Microservices for team Achievers11-DevOps.
Work in the current directory: ~/Petclinic-Platform-G11/petclinic-platform

## FIXED VALUES — NEVER CHANGE THESE:
- AWS Account ID: 118821711881
- Region: us-east-1
- Cluster name: petclinic-eks
- Namespace: petclinic
- ECR registry: 118821711881.dkr.ecr.us-east-1.amazonaws.com
- ECR repo prefix: petclinic
- App repo: Achievers11-DevOps/petclinic-microservices
- Platform repo: Achievers11-DevOps/petclinic-k8s-platform
- Domain: gregddevops.com.ng
- Route 53 Zone ID: Z10395433FWC00PFCKRCW
- ALB Hosted Zone ID: Z35SXDOTRQ7X7K (us-east-1 — NEVER change this)
- ACM Certificate ARN: arn:aws:acm:us-east-1:118821711881:certificate/71061191-67c2-455b-bd95-82bd16a78829
- Terraform state S3 bucket: petclinic-tfstate-118821711881
- Terraform DynamoDB table: petclinic-terraform-locks
- RDS identifier: petclinic-mysql
- RDS database name: petclinic
- DB secret name: petclinic/database-credentials
- OpenAI secret name: petclinic/openai-api-key
- ArgoCD namespace: argocd
- Monitoring namespace: monitoring
- Git working branch: dev
- ArgoCD watches: dev branch

## CURRENT STATE — VERIFIED BEFORE STARTING:
- Terraform files exist: terraform/backend.tf, main.tf, modules/, variables.tf
- Helm chart exists: helm/petclinic-service/
- Helm values exist: helm-values/ (all 8 services + dev.yaml)
- ArgoCD folder exists: argocd/
- k8s folder exists: k8s/
- EKS cluster: DOES NOT EXIST — needs creating
- ECR repos: DO NOT EXIST in us-east-1 — needs creating
- ACM cert: REQUESTED, validation PENDING (Route 53 CNAME already added)
- Git branch: currently on main, need to work on dev branch

## CRITICAL — DO THESE FIRST BEFORE ANY OTHER STEP:
1. git checkout dev || git checkout -b dev
2. Update terraform/variables.tf: change aws_region default from "af-south-1" to "us-east-1"
3. Update terraform/backend.tf: change region from "af-south-1" to "us-east-1"
4. Verify S3 backend bucket exists in us-east-1:
   aws s3 ls s3://petclinic-tfstate-118821711881 --region us-east-1
   If missing: aws s3 mb s3://petclinic-tfstate-118821711881 --region us-east-1
5. Verify DynamoDB table exists:
   aws dynamodb describe-table --table-name petclinic-terraform-locks --region us-east-1
   If missing: aws dynamodb create-table --table-name petclinic-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST --region us-east-1

## PHASE 1 — TERRAFORM (run in terraform/ directory)
cd terraform/
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan -auto-approve

Wait for completion. Expected outputs:
- cluster_name = petclinic-eks
- cluster_endpoint = https://...
- ecr_urls with all 8 repos
- db_endpoint (RDS MySQL)

After apply run:
aws eks update-kubeconfig --region us-east-1 --name petclinic-eks
kubectl get nodes
Wait until nodes show Ready.

## PHASE 2 — NAMESPACES
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl get namespaces

## PHASE 3 — AWS LOAD BALANCER CONTROLLER
Step 1: Check if IAM policy exists:
aws iam get-policy \
  --policy-arn arn:aws:iam::118821711881:policy/AWSLoadBalancerControllerIAMPolicy \
  --region us-east-1 2>/dev/null && echo "EXISTS" || echo "MISSING"

If MISSING — create it:
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

Step 2: Associate OIDC:
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 --cluster petclinic-eks --approve

Step 3: Create IAM service account:
eksctl create iamserviceaccount \
  --cluster=petclinic-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::118821711881:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve --region us-east-1 \
  --override-existing-serviceaccounts

Step 4: Install via Helm:
VPC_ID=$(aws eks describe-cluster --name petclinic-eks \
  --region us-east-1 \
  --query 'cluster.resourcesVpcConfig.vpcId' --output text)

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=petclinic-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID

kubectl get deployment -n kube-system aws-load-balancer-controller
Wait until READY shows 2/2.

## PHASE 4 — EXTERNAL SECRETS OPERATOR
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n kube-system --set installCRDs=true

sleep 60

Check if ClusterSecretStore exists in k8s/external-secrets/:
ls k8s/external-secrets/

If cluster-secret-store.yaml exists — update region to us-east-1 and apply:
sed -i 's/af-south-1/us-east-1/g' k8s/external-secrets/cluster-secret-store.yaml
kubectl apply -f k8s/external-secrets/cluster-secret-store.yaml

If missing — create it:
cat > k8s/external-secrets/cluster-secret-store.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: kube-system
EOF
kubectl apply -f k8s/external-secrets/cluster-secret-store.yaml

Update all ESO manifests region from af-south-1 to us-east-1:
sed -i 's/af-south-1/us-east-1/g' k8s/external-secrets/*.yaml
kubectl apply -f k8s/external-secrets/db-secret.yaml
kubectl apply -f k8s/external-secrets/openai-secret.yaml
sleep 30
kubectl get externalsecret -n petclinic

## PHASE 5 — SECRETS MANAGER
Check if secrets exist:
aws secretsmanager describe-secret \
  --secret-id petclinic/database-credentials \
  --region us-east-1 2>/dev/null && echo "DB SECRET EXISTS" || echo "MISSING"

aws secretsmanager describe-secret \
  --secret-id petclinic/openai-api-key \
  --region us-east-1 2>/dev/null && echo "OPENAI SECRET EXISTS" || echo "MISSING"

If DB secret MISSING — get RDS endpoint from Terraform output then create:
RDS_ENDPOINT=$(terraform output -raw db_endpoint 2>/dev/null || \
  aws rds describe-db-instances \
  --db-instance-identifier petclinic-mysql \
  --region us-east-1 \
  --query 'DBInstances[0].Endpoint.Address' --output text)

aws secretsmanager create-secret \
  --name petclinic/database-credentials \
  --region us-east-1 \
  --secret-string "{\"username\":\"petclinic\",\"password\":\"PetClinic2026!\",\"host\":\"$RDS_ENDPOINT\",\"port\":\"3306\",\"dbname\":\"petclinic\"}"

If OpenAI secret MISSING:
aws secretsmanager create-secret \
  --name petclinic/openai-api-key \
  --secret-string "sk-demo" \
  --region us-east-1

## PHASE 6 — ECR LOGIN + PULL SECRET
aws ecr get-login-password --region us-east-1 | \
  kubectl create secret docker-registry ecr-secret \
  --docker-server=118821711881.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace petclinic \
  --dry-run=client -o yaml | kubectl apply -f -

## PHASE 7 — CHECK ECR IMAGES
Check if images exist in us-east-1 ECR:
for svc in config-server discovery-server api-gateway customers-service vets-service visits-service genai-service admin-server; do
  COUNT=$(aws ecr describe-images \
    --repository-name petclinic/$svc \
    --region us-east-1 \
    --query 'length(imageDetails)' \
    --output text 2>/dev/null || echo "0")
  echo "$svc: $COUNT images"
done

If ALL services show 0 images — check af-south-1 for existing images:
aws ecr describe-repositories --region af-south-1 \
  --query 'repositories[*].repositoryName' --output table

If af-south-1 has spring-petclinic-g11 images — we need to build and push
to us-east-1. Run Maven build:
cd ~/petclinic-microservices || cd ~/Petclinic-Platform-G11/spring-petclinic-microservices
./mvnw clean install -P buildDocker -DskipTests

Then tag and push all 8 images to us-east-1 ECR:
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS \
  --password-stdin 118821711881.dkr.ecr.us-east-1.amazonaws.com

for svc in config-server discovery-server api-gateway customers-service vets-service visits-service genai-service admin-server; do
  docker tag springcommunity/spring-petclinic-$svc:latest \
    118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic/$svc:latest
  docker push 118821711881.dkr.ecr.us-east-1.amazonaws.com/petclinic/$svc:latest
  echo "Pushed $svc"
done

## PHASE 8 — HELM DEPLOYMENT
Get RDS endpoint:
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier petclinic-mysql \
  --region us-east-1 \
  --query 'DBInstances[0].Endpoint.Address' --output text)
echo "RDS: $RDS_ENDPOINT"

ECR_REGISTRY=118821711881.dkr.ecr.us-east-1.amazonaws.com

Update all helm-values files — change af-south-1 to us-east-1 in image repositories:
sed -i 's/af-south-1/us-east-1/g' helm-values/*.yaml
sed -i 's/spring-petclinic-g11/petclinic/g' helm-values/*.yaml

cd ~/Petclinic-Platform-G11/petclinic-platform

Deploy config-server FIRST and wait:
helm upgrade --install config-server helm/petclinic-service/ \
  -n petclinic \
  -f helm-values/config-server.yaml \
  -f helm-values/dev.yaml \
  --set image.repository=$ECR_REGISTRY/petclinic/config-server \
  --set image.tag=latest \
  --set imagePullSecrets[0].name=ecr-secret
kubectl rollout status deployment/config-server -n petclinic --timeout=5m

Deploy discovery-server SECOND and wait:
helm upgrade --install discovery-server helm/petclinic-service/ \
  -n petclinic \
  -f helm-values/discovery-server.yaml \
  -f helm-values/dev.yaml \
  --set image.repository=$ECR_REGISTRY/petclinic/discovery-server \
  --set image.tag=latest \
  --set imagePullSecrets[0].name=ecr-secret
kubectl rollout status deployment/discovery-server -n petclinic --timeout=5m

Deploy remaining 6 services:
for SERVICE in api-gateway customers-service visits-service vets-service genai-service admin-server; do
  helm upgrade --install $SERVICE helm/petclinic-service/ \
    -n petclinic \
    -f helm-values/$SERVICE.yaml \
    -f helm-values/dev.yaml \
    --set image.repository=$ECR_REGISTRY/petclinic/$SERVICE \
    --set image.tag=latest \
    --set imagePullSecrets[0].name=ecr-secret \
    --set env.SPRING_DATASOURCE_URL="jdbc:mysql://$RDS_ENDPOINT:3306/petclinic?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
  echo "Deployed $SERVICE"
done

kubectl get pods -n petclinic

## PHASE 9 — ARGOCD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=5m

ARGOCD_PASSWORD=$(kubectl -n argocd get secret \
  argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD password: $ARGOCD_PASSWORD"

Check if argocd/petclinic-app.yaml exists:
ls argocd/

If exists — update targetRevision to dev and apply:
sed -i 's/targetRevision: main/targetRevision: dev/g' argocd/petclinic-app.yaml
sed -i 's/namespace: petclinic-dev/namespace: petclinic/g' argocd/petclinic-app.yaml
kubectl apply -f argocd/petclinic-app.yaml

If missing — create it:
cat > argocd/petclinic-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: petclinic
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Achievers11-DevOps/petclinic-k8s-platform
    targetRevision: dev
    path: helm-values
  destination:
    server: https://kubernetes.default.svc
    namespace: petclinic
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
kubectl apply -f argocd/petclinic-app.yaml

sleep 30
kubectl get applications -n argocd

Port-forward ArgoCD for UI access:
kubectl port-forward svc/argocd-server -n argocd 8090:443 &
echo "ArgoCD UI: https://localhost:8090"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"

## PHASE 10 — INGRESS + HTTPS
Check if k8s/ingress/petclinic-ingress.yaml exists:
ls k8s/ingress/ 2>/dev/null || mkdir -p k8s/ingress

Update or create ingress:
cat > k8s/ingress/petclinic-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petclinic-ingress
  namespace: petclinic
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:118821711881:certificate/71061191-67c2-455b-bd95-82bd16a78829
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
spec:
  rules:
    - host: gregddevops.com.ng
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-gateway
                port:
                  number: 8080
EOF
kubectl apply -f k8s/ingress/petclinic-ingress.yaml

Wait 3 minutes then get ALB:
sleep 180
ALB=$(kubectl get ingress petclinic-ingress \
  -n petclinic \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB: $ALB"

Update Route 53:
aws route53 change-resource-record-sets \
  --hosted-zone-id Z10395433FWC00PFCKRCW \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"gregddevops.com.ng\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"Z35SXDOTRQ7X7K\",
          \"DNSName\": \"$ALB\",
          \"EvaluateTargetHealth\": true
        }
      }
    }]
  }"

## PHASE 11 — MONITORING
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

kubectl get pods -n monitoring

Port-forward for local access:
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 &
kubectl port-forward svc/monitoring-kube-prometheus-prometheus \
  -n monitoring 9090:9090 &
echo "Grafana: http://localhost:3000 (admin/admin123)"
echo "Prometheus: http://localhost:9090"

## PHASE 12 — COMMIT TO DEV BRANCH
cd ~/Petclinic-Platform-G11/petclinic-platform
git add -A
git commit -m "GPM-226: deploy petclinic-eks us-east-1 - all services running"
git push origin dev

## PHASE 13 — FINAL VERIFICATION
kubectl get nodes
kubectl get pods -n petclinic
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get ingress -n petclinic
kubectl get applications -n argocd
kubectl get externalsecret -n petclinic

Check ACM cert status:
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:118821711881:certificate/71061191-67c2-455b-bd95-82bd16a78829 \
  --region us-east-1 \
  --query 'Certificate.Status'

Check domain:
curl -I https://gregddevops.com.ng 2>/dev/null | head -5 || \
  echo "HTTPS not ready yet - cert still validating"

## RULES — ALWAYS FOLLOW:
1. Always use region us-east-1 — never af-south-1
2. Always use namespace petclinic — never petclinic-staging or petclinic-dev
3. Always use cluster name petclinic-eks
4. Always use ECR prefix petclinic/ — never spring-petclinic-g11
5. ArgoCD always watches dev branch — never main
6. If a resource exists already — skip creation, move on
7. If terraform apply fails — show full error, fix it, retry
8. If a pod crashloops — check logs immediately and fix before continuing
9. Never hardcode secrets — always use Secrets Manager
10. After every phase — show clear status summary before moving to next phase
11. ALB Hosted Zone ID for us-east-1 is Z35SXDOTRQ7X7K — never change this

Start with PHASE 1 — check S3 and DynamoDB backend first,
update region in terraform files, then run terraform init and apply.
Report clearly after each phase before proceeding.
