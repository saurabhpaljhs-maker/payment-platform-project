# Runbook: Payment Gateway Incidents

> Owner: Platform DevOps Team | Last Updated: 2025  
> For emergencies: Slack `#payments-oncall` or PagerDuty

---

## 1. Payment Gateway Down

**Alert**: `PaymentGatewayNoTransactions` — critical  
**Impact**: All payment processing halted

### Immediate Steps (< 5 min)

```bash
# 1. Check pod status
kubectl get pods -n payments -l app=payment-gateway

# 2. Check recent events
kubectl describe deployment payment-gateway -n payments | tail -20

# 3. Check logs (last 100 lines)
kubectl logs -n payments -l app=payment-gateway --tail=100

# 4. If pods are CrashLoopBackOff — check for OOM
kubectl describe pod <pod-name> -n payments | grep -A5 "Last State"
```

### If Pods Are Not Starting

```bash
# Check resource limits — GKE node capacity
kubectl top nodes
kubectl top pods -n payments

# Check if image pull is failing (Artifact Registry auth issue)
kubectl describe pod <pod-name> -n payments | grep -A10 "Events"

# Emergency: Scale down and back up to force reschedule
kubectl rollout restart deployment/payment-gateway -n payments
```

### If Code Deployment Caused Issue — Rollback

```bash
./ci-cd/scripts/rollback.sh payment-gateway payments
```

---

## 2. High Transaction Failure Rate {#high-failure-rate}

**Alert**: `PaymentGatewayHighFailureRate` — critical (>2% failures)

```bash
# Check error distribution in logs
kubectl logs -n payments -l app=payment-gateway --tail=500     | grep "ERROR" | sort | uniq -c | sort -rn | head -20

# Check downstream services
kubectl get pods -n payments -l app=transaction-service
kubectl logs -n payments -l app=transaction-service --tail=100 | grep ERROR
```

---

## 3. DB Connection Pool Exhausted {#db-pool}

**Alert**: `CloudSQLConnectionsHigh` — critical (>180 connections)

```bash
# Check which pods are consuming most connections
kubectl exec -n payments deployment/payment-gateway --     curl -s http://localhost:8080/actuator/metrics/hikaricp.connections.active

# Emergency: Restart pods to recycle connections
kubectl rollout restart deployment/payment-gateway -n payments
kubectl rollout restart deployment/transaction-service -n payments
```

---

## Escalation Path

| Time | Action |
|---|---|
| 0-5 min | Follow runbook above |
| 5-15 min | Escalate to on-call lead via PagerDuty |
| 15+ min | Invoke incident bridge: `#incident-bridge` Slack |
| 30+ min | Consider full environment rollback via Terraform |
