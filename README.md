# payment-platform-devops

> DevOps infrastructure and CI/CD pipeline for a microservices-based payment processing platform running on Google Cloud Platform (GCP). Manages 15+ services handling transaction processing, payment gateway, and notification workflows.

![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

---

## 🏦 Project Context

This repository contains the complete DevOps setup for a **banking and payment processing platform** — similar to infrastructure managed for enterprise payment clients in the fintech/banking domain.

The platform processes:
- **Payment Gateway** — card authorization, POS terminal integration
- **Transaction Service** — real-time transaction processing & reconciliation
- **Notification Service** — SMS/email alerts for transaction events

**Scale**: 15+ microservices | 3 environments (dev/staging/prod) | ~2000 transactions/minute peak load

---

## 📁 Repository Structure

```
payment-platform-devops/
│
├── terraform/                          # Infrastructure as Code (GCP)
│   ├── modules/
│   │   ├── gke/                        # GKE cluster module
│   │   ├── vpc/                        # VPC + subnets + firewall
│   │   └── cloudsql/                   # Cloud SQL (PostgreSQL) module
│   └── environments/
│       ├── dev/                        # Dev environment config
│       ├── staging/                    # Staging environment config
│       └── prod/                       # Production environment config
│
├── ci-cd/                              # Jenkins CI/CD pipelines
│   ├── jenkins/pipelines/
│   │   ├── Jenkinsfile.payment-gateway
│   │   ├── Jenkinsfile.transaction-service
│   │   └── Jenkinsfile.shared-deploy
│   └── scripts/
│       ├── deploy.sh
│       ├── rollback.sh
│       └── smoke-test.sh
│
├── monitoring/                         # Observability stack
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── rules/
│   │       ├── payment-alerts.yml      # Payment-specific alert rules
│   │       └── infra-alerts.yml
│   ├── grafana/
│   │   └── dashboards/
│   │       ├── payment-gateway.json    # Custom payment dashboard
│   │       └── transaction-throughput.json
│   └── alertmanager/
│       └── alertmanager.yml
│
├── k8s/                                # Kubernetes manifests
│   ├── namespaces/
│   ├── rbac/
│   └── services/
│       ├── payment-gateway/
│       ├── transaction-service/
│       └── notification-service/
│
└── docs/
    ├── architecture.md
    ├── runbook-payment-gateway.md      # Incident runbook
    └── onboarding.md
```

---

## 🏗️ Architecture Overview

```
                        ┌─────────────────────────────────────────┐
                        │           GCP Project: payments-prod     │
                        │                                          │
                        │  ┌─────────────────────────────────┐    │
   Internet / POS  ────────►  Cloud Load Balancer (HTTPS)    │    │
   Terminals            │  └──────────────┬──────────────────┘    │
                        │                 │                        │
                        │  ┌──────────────▼──────────────────┐    │
                        │  │     GKE Cluster (prod)           │    │
                        │  │                                  │    │
                        │  │  [payment-gateway]  port: 8080   │    │
                        │  │  [transaction-svc]  port: 8081   │    │
                        │  │  [notification-svc] port: 8082   │    │
                        │  │  [fraud-detection]  port: 8083   │    │
                        │  │                                  │    │
                        │  └──────────────┬──────────────────┘    │
                        │                 │                        │
                        │  ┌──────────────▼──────────────────┐    │
                        │  │   Cloud SQL (PostgreSQL 14)      │    │
                        │  │   transactions_db | accounts_db  │    │
                        │  └─────────────────────────────────┘    │
                        │                                          │
                        └─────────────────────────────────────────┘
```

---

## ⚙️ Infrastructure (Terraform)

| Component | GCP Service | Purpose |
|---|---|---|
| Container cluster | GKE Autopilot | Run all microservices |
| Database | Cloud SQL PostgreSQL | Transaction & account data |
| Networking | VPC + Private Subnets | Isolated network |
| Secrets | Secret Manager | DB passwords, API keys |
| Registry | Artifact Registry | Docker images |
| Logs | Cloud Logging | Centralized logs |
| Metrics | Cloud Monitoring | Infra metrics |

```bash
# Provision prod environment
cd terraform/environments/prod
terraform init -backend-config="bucket=payments-tfstate-prod"
terraform plan -var-file="prod.tfvars"
terraform apply -auto-approve
```

---

## 🚀 CI/CD Pipeline

```
Developer PR → Jenkins → Maven Build → Unit Test → SonarQube
                                                        │
                                              Quality Gate Pass?
                                                    │
                                              Docker Build & Push
                                              (GCP Artifact Registry)
                                                    │
                                           Deploy to GKE (staging)
                                                    │
                                           Integration Tests
                                                    │
                                           Manual Approval (prod)
                                                    │
                                           Deploy to GKE (prod)
                                                    │
                                           Health Check + Smoke Test
                                                    │
                                     Pass ──────────┴──────────── Fail
                                       │                            │
                                  Slack ✅                    Auto Rollback
                                                              + Slack ❌
```

---

## 📊 Monitoring & Alerting

### Key Metrics Monitored
| Metric | Warning | Critical | Action |
|---|---|---|---|
| Transaction success rate | < 99.5% | < 98% | Page on-call |
| Payment gateway latency p99 | > 500ms | > 2000ms | Investigate |
| Failed transactions/min | > 10 | > 50 | Auto-scale + alert |
| Pod restarts | > 3/hour | > 10/hour | Check OOMKilled |
| Cloud SQL connections | > 80% | > 95% | Connection pool check |

### Grafana Dashboards
- **Payment Gateway Dashboard** — TPS, success rate, latency percentiles
- **Transaction Throughput** — peak load trends, error rates by type

---

## 🔐 Security Practices

- All secrets in **GCP Secret Manager** — never in code or env vars
- GKE nodes use **Workload Identity** — no service account key files
- **Network Policy** enforced — services can only talk to what they need
- **PodSecurityStandard: restricted** on payment namespace
- Docker images scanned via **Trivy** in every pipeline run
- **RBAC**: developers get read-only; pipeline SA gets deploy-only

---

## 🌍 Environments

| Env | GKE Cluster | Replicas | Auto-scale | Purpose |
|---|---|---|---|---|
| dev | gke-payments-dev | 1 | No | Developer testing |
| staging | gke-payments-staging | 2 | No | Integration + QA |
| prod | gke-payments-prod | 3 | Yes (3-10) | Live traffic |

---

## 🚨 Incident Runbooks

- [Payment Gateway Down](docs/runbook-payment-gateway.md)
- [High Transaction Failure Rate](docs/runbook-payment-gateway.md#high-failure-rate)
- [Database Connection Pool Exhausted](docs/runbook-payment-gateway.md#db-pool)

---

## 👨‍💻 Author

**Your Name** — DevOps Engineer  
Experience: HCL Technologies → NCR Voyix/Atleos | Banking & Payments Domain  
[LinkedIn](https://linkedin.com/in/yourprofile) | [GitHub](https://github.com/yourusername)
