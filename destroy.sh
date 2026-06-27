#!/bin/bash
set -e

echo "🧹 Starting EKS lab cleanup..."

# ─── KUBECONFIG ────────────────────────────────────────
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig \
  --region "$(terraform output -raw region)" \
  --name "$(terraform output -raw cluster_name)" 2>/dev/null || true

# ─── DELETE INGRESSES ──────────────────────────────────
# Must be deleted before terraform destroy or ALBs will
# block subnet/IGW deletion and hang for 20+ minutes
echo "🌐 Deleting ingresses to trigger ALB removal..."
kubectl delete ingress --all -n default 2>/dev/null || true
kubectl delete ingress --all -n monitoring 2>/dev/null || true

# ─── WAIT FOR ALBS TO BE DELETED ───────────────────────
echo "⏳ Waiting for ALBs to be fully deleted by controller..."
echo "   Checking EC2 for remaining load balancers..."

VPC_ID=$(terraform output -raw vpc_id)

while true; do
  LB_COUNT=$(aws elb describe-load-balancers \
    --query "length(LoadBalancerDescriptions[?VPCId=='${VPC_ID}'])" \
    --output text 2>/dev/null || echo "0")

  ALB_COUNT=$(aws elbv2 describe-load-balancers \
    --query "length(LoadBalancers[?VpcId=='${VPC_ID}'])" \
    --output text 2>/dev/null || echo "0")

  TOTAL=$((LB_COUNT + ALB_COUNT))

  if [ "$TOTAL" -eq 0 ]; then
    echo "✅ All load balancers deleted"
    break
  fi

  echo "   Still waiting... ${TOTAL} load balancer(s) remaining"
  sleep 10
done

# ─── DELETE REMAINING ENIS ─────────────────────────────
# ALB controller sometimes leaves ENIs behind that block subnet deletion
echo "🔌 Cleaning up any orphaned ENIs..."
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=status,Values=available" \
  --query "NetworkInterfaces[*].NetworkInterfaceId" \
  --output text 2>/dev/null || echo "")

if [ -n "$ENI_IDS" ]; then
  for ENI in $ENI_IDS; do
    echo "   Deleting ENI: $ENI"
    aws ec2 delete-network-interface --network-interface-id "$ENI" 2>/dev/null || true
  done
else
  echo "✅ No orphaned ENIs found"
fi

# ─── TERRAFORM DESTROY ─────────────────────────────────
echo "💣 Running terraform destroy..."
terraform destroy -auto-approve

echo "✅ Done! Cluster fully destroyed."