#!/bin/bash
set -e

# ─── CONFIG ────────────────────────────────────────────
CERTIFICATE_ARN="arn:aws:acm:eu-north-1:572472610359:certificate/79e11843-fe21-4d78-8097-7da9af1168f4"
HOSTED_ZONE_ID="Z0888153LTHHUYZ48Q3O"
REGION="eu-north-1"

echo "🚀 Deploying EKS lab cluster..."

# ─── TERRAFORM ─────────────────────────────────────────
echo "📦 Running terraform apply..."
terraform apply -auto-approve

# ─── KUBECONFIG ────────────────────────────────────────
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig \
  --region "$(terraform output -raw region)" \
  --name "$(terraform output -raw cluster_name)"

# ─── HELM — LB CONTROLLER ──────────────────────────────
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

# ─── WAIT FOR LB CONTROLLER ────────────────────────────
echo "⏳ Waiting for Load Balancer Controller to be ready..."
kubectl rollout status deployment/aws-load-balancer-controller \
  -n kube-system \
  --timeout=120s

# ─── HELM — PROMETHEUS ─────────────────────────────────
echo "⚙️  Installing kube-prometheus-stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set grafana.grafana\.ini.auth.disable_login_form=false \
  --set grafana.grafana\.ini.security.admin_password=admin \
  --set grafana.grafana\.ini.users.allow_sign_up=false \
  --set grafana.adminUser=admin \
  --set grafana.forceDeployDatasources=true \
  --set prometheus.prometheusSpec.retention=1d \
  --set alertmanager.enabled=true

# ─── WAIT FOR PROMETHEUS ───────────────────────────────
echo "⏳ Waiting for Prometheus stack to be ready..."
kubectl rollout status deployment/kube-prometheus-stack-grafana \
  -n monitoring \
  --timeout=180s

# ─── APP ───────────────────────────────────────────────
echo "🐳 Deploying hello-eks-nodejs app..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# ─── INGRESSES ─────────────────────────────────────────
echo "🌐 Deploying ingresses with TLS..."
envsubst < k8s/ingress.yaml | kubectl apply -f -
envsubst < k8s/grafana-ingress.yaml | kubectl apply -f -

# ─── WAIT FOR ALB DNS ──────────────────────────────────
echo "⏳ Waiting for ALB DNS names to be assigned..."

wait_for_ingress() {
  local NAME=$1
  local NAMESPACE=$2
  local ADDRESS=""
  while [ -z "$ADDRESS" ]; do
    ADDRESS=$(kubectl get ingress "$NAME" -n "$NAMESPACE" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -z "$ADDRESS" ]; then
      echo "   Waiting for $NAME ingress address..." >&2
      sleep 10
    fi
  done
  echo "$ADDRESS"
}

HELLO_ALB=$(wait_for_ingress "hello-eks-nodejs" "default")
GRAFANA_ALB=$HELLO_ALB   # same ALB due to group.name

echo "✅ hello ALB: $HELLO_ALB"
echo "✅ grafana ALB: $GRAFANA_ALB"

# ─── ROUTE53 RECORDS ───────────────────────────────────
echo "🌍 Creating Route53 DNS records..."

upsert_record() {
  local NAME=$1
  local ALB=$2

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${NAME}.espi.click\",
          \"Type\": \"CNAME\",
          \"TTL\": 60,
          \"ResourceRecords\": [{
            \"Value\": \"${ALB}\"
          }]
        }
      }]
    }" > /dev/null

  echo "✅ ${NAME}.espi.click → ${ALB}"
}

upsert_record "hello" "$HELLO_ALB"
upsert_record "grafana" "$GRAFANA_ALB"

# ─── DONE ──────────────────────────────────────────────
echo ""
echo "✅ Done! Cluster is up."
echo ""
echo "🌐 https://hello.espi.click"
echo "📊 https://grafana.espi.click  (admin/admin)"