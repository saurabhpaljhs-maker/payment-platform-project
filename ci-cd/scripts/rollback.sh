#!/bin/bash
# Emergency Rollback Script — Payment Platform GKE
# Usage: ./rollback.sh <service-name> <namespace> <previous-image-tag>
set -euo pipefail

SERVICE="${1:?Error: service name required}"
NAMESPACE="${2:-payments}"
PREV_TAG="${3:-}"
GCP_PROJECT="${GCP_PROJECT:-payments-platform-prod}"
GCP_REGION="${GCP_REGION:-us-central1}"
GKE_CLUSTER="${GKE_CLUSTER:-payments-gke-prod}"
ARTIFACT_REPO="us-central1-docker.pkg.dev/${GCP_PROJECT}/payments"

echo "================================================"
echo "  PAYMENT PLATFORM EMERGENCY ROLLBACK"
echo "================================================"
echo "  Service:   ${SERVICE}"
echo "  Namespace: ${NAMESPACE}"
echo "  Cluster:   ${GKE_CLUSTER}"
if [ -n "${PREV_TAG}" ]; then
    echo "  Target:    ${ARTIFACT_REPO}/${SERVICE}:${PREV_TAG}"
fi
echo "================================================"
echo ""
read -rp "Confirm rollback? Type 'yes' to proceed: " confirm
[[ "$confirm" != "yes" ]] && { echo "Aborted."; exit 0; }

echo ""
echo "Authenticating to GKE cluster..."
gcloud container clusters get-credentials "${GKE_CLUSTER}"     --region "${GCP_REGION}" --project "${GCP_PROJECT}"

echo "Current deployment status:"
kubectl rollout history "deployment/${SERVICE}" -n "${NAMESPACE}" | tail -5

if [ -n "${PREV_TAG}" ]; then
    echo ""
    echo "Setting image to ${ARTIFACT_REPO}/${SERVICE}:${PREV_TAG}..."
    kubectl set image "deployment/${SERVICE}"         "${SERVICE}=${ARTIFACT_REPO}/${SERVICE}:${PREV_TAG}"         -n "${NAMESPACE}"
else
    echo ""
    echo "Rolling back to previous version..."
    kubectl rollout undo "deployment/${SERVICE}" -n "${NAMESPACE}"
fi

echo "Waiting for rollback to complete..."
kubectl rollout status "deployment/${SERVICE}"     -n "${NAMESPACE}" --timeout=180s

echo ""
echo "Post-rollback pod status:"
kubectl get pods -n "${NAMESPACE}" -l "app=${SERVICE}"

echo ""
echo "✅ Rollback complete for ${SERVICE}"
echo "ACTION REQUIRED: Raise incident ticket and notify on-call lead"
