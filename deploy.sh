#!/bin/bash
set -e
# ─── CONFIG ────────────────────────────────────────────
CERTIFICATE_ARN="arn:aws:acm:eu-north-1:572472610359:certificate/79e11843-fe21-4d78-8097-7da9af1168f4"
echo "🚀 Deploying EKS lab cluster..."

# ─── TERRAFORM ─────────────────────────────────────────
echo "📦 Running terraform apply..."
terraform apply -auto-approve

# ─── KUBECONFIG ────────────────────────────────────────
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig \
  --region "$(terraform output -raw region)" \
  --name "$(terraform output -raw cluster_name)"

# ─── HELM ──────────────────────────────────────────────
echo "⚙️  Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
helm repo update


helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$(terraform output -raw cluster_name)" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$(terraform output -raw lb_controller_role_arn)" \
  --set region="$(terraform output -raw region)" \
  --set vpcId="$(terraform output -raw vpc_id)"


echo "⚙️  Installing Prometheus"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.retention=1d \
  --set alertmanager.enabled=true

# ─── WAIT FOR CONTROLLER ───────────────────────────────
echo "⏳ Waiting for Load Balancer Controller to be ready..."
kubectl rollout status deployment/aws-load-balancer-controller \
  -n kube-system \
  --timeout=120s

# ─── APP ───────────────────────────────────────────────
echo "🐳 Deploying hello-eks-nodejs app..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "🌐 Deploying ingress with TLS..."
envsubst < .k8s/ingress.yaml | kubectl apply -f -

echo "✅ Done! Cluster is up."
echo ""
echo "Run 'kubectl get ingress' to get the ALB URL."
echo "Or visit https://hello.espi.click once DNS propagates."