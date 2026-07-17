# Engineering Docs

Practical engineering guides and checklists for platform, DevOps, SRE, cloud migration, delivery, Terraform, Kubernetes, and operations work.

This repository contains documentation and small supporting documentation tooling. Production code, automation, and infrastructure implementations belong in their own repositories.

## Documentation

### AWS

* [AWS and Hybrid Disaster Recovery Guide](aws/disaster-recovery-aws-hybrid.md) — Practical DR concepts for AWS and hybrid environments, including RTO/RPO, backup and restore, pilot light, warm standby, active-active, testing, and failback.
* [AWS Connectivity Options — Practical DevOps Reference](aws/aws-connectivity-options.md) — A practical reference for VPC peering, Transit Gateway, PrivateLink, VPN, Direct Connect, routing tradeoffs, and connectivity decision points.
* [AWS Multi-Account Basics](aws/aws-multi-account-basics.md) — A beginner-friendly introduction to AWS multi-account architecture, account responsibilities, centralized access, security, logging and basic cross-account connectivity.
* [AWS to Azure Service Comparison](aws/aws-azure-service-comparison.md) — Approximate AWS to Azure service equivalents, with notes on where the mappings differ.

### Kubernetes

* [Argo Rollouts](kubernetes/argo-rollouts.md) — A conceptual guide to progressive delivery with Argo Rollouts, including Blue/Green, Canary, traffic routing, analysis, rollback behavior, and Argo CD responsibilities.
* [Kubernetes CNI Comparison](kubernetes/kubernetes-cni-comparison.md) — A comparison of common Kubernetes networking plugins and managed-cloud defaults, including Cilium, Calico, Amazon VPC CNI, AKS, and GKE considerations.
* [Kubernetes Internals](kubernetes/kubernetes-internals.md) — A practical walkthrough of Kubernetes internal workflows with diagrams for deployments, routing, rollouts, autoscaling, restarts, Vault injection, and GitOps.
* [Kubernetes Migration Checklist](kubernetes/kubernetes-migration-checklist.md) — A concise checklist for moving workloads into or between Kubernetes clusters, covering assessment, manifests, data, traffic, validation, and cleanup.
* [Kubernetes Multi-Site DR](kubernetes/kubernetes-multi-site-dr.md) — An active-active multi-Region DR design on AWS with two EKS clusters, Argo CD GitOps, DynamoDB Global Tables, and global traffic routing.
* [Kubernetes Resource Sizing](kubernetes/kubernetes-resource-sizing.md) — A guide to sizing Kubernetes workload CPU and memory requests using VPA and Goldilocks recommendations.
* [Rancher 1.6 to AWS EKS Migration](kubernetes/rancher-1-6-to-aws-eks-migration.md) — A practical playbook for converting Rancher 1.6 Cattle stacks into Kubernetes resources on EKS.
* [FluxCD and Argo CD GitOps Basics](kubernetes/fluxcd-argocd-gitops.md) — A practical comparison of FluxCD and Argo CD, including GitOps fundamentals, reconciliation, Helm, Kustomize, drift correction, and troubleshooting.

### Terraform

* [Terraform State Separation in Large AWS Organizations](terraform/terraform-state-separation.md) — An operating model for splitting Terraform state across AWS accounts, regions, environments, teams, and lifecycle boundaries.
* [Breaking a Terraform Monolith into Independent State Components](terraform/terraform-monolith-decomposition.md) — A migration guide for decomposing a large Terraform root module into smaller state components without unnecessary risk.
* [Terraform and Terragrunt AWS Infrastructure Structure](terraform/terraform-terragrunt-aws-structure.md) — A recommended Terraform and Terragrunt repository structure for reusable modules, service compositions, and environment-specific live configuration.

### Security

* [Secret Management Guide](security/secret-management-guide.md) — A practical guide to managing secrets with Ansible Vault, Terraform, AWS Secrets Manager, SSM Parameter Store, and HashiCorp Vault, including rekey vs rotation, CI/CD patterns, and common mistakes.
* [Security Compliance Quick Start](security/security-compliance-quick-start.md) — A practical roadmap for starting SOC 2 and ISO/IEC 27001 work, including scope, controls, policies, evidence, audits, and ownership.

### CI/CD

* [CI/CD Standards](ci-cd/ci-cd-standards.md) — A baseline for CI/CD pipeline structure, quality gates, artifact handling, deployment practices, rollback, and operational expectations.

### Delivery and operations

* [ADR Template](delivery/adr-template.md) — A lightweight template for recording technical decisions, context, tradeoffs, consequences, and example decision records.
* [AI-Assisted Development](delivery/ai-assisted-development.md) — A practical guide for using AI coding tools with repository context, scoped changes, validation, review, commit discipline, and secret handling.
* [Cloud Migration Risk Register](delivery/cloud-migration-risk-register.md) — A compact risk register template for cloud and platform migration work, including impact, likelihood, owner, mitigation, and status.
* [Incident Response Runbook](delivery/incident-response-runbook.md) — A practical incident workflow covering severity, roles, communication, investigation, mitigation, post-incident review, and readiness.
* [Legacy Application Development](delivery/legacy-application-development.md) — A workflow for using AI agents on existing applications while preserving context, limiting scope, validating changes, and carrying work across sessions.
* [Observability Checklist](delivery/observability-checklist.md) — A checklist for service logs, metrics, traces, alerts, dashboards, SLOs, and operational visibility during incidents.
* [Production Readiness Checklist](delivery/production-readiness-checklist.md) — A service readiness checklist covering reliability, security, deployment, observability, scalability, data, and operational ownership.
* [Project Delivery Playbook](delivery/project-delivery-playbook.md) — A senior-engineer playbook for project kickoff, alignment, planning, delivery tracking, communication, risks, and decisions.

## PDF conversion

See [PDF conversion tooling](tools/pdf-conversion/README.md).
