# Engineering Docs

Practical engineering guides and checklists for platform, DevOps, SRE, cloud migration, delivery, Terraform, Kubernetes, and operations work.

This repository contains documentation and small supporting documentation tooling. Production code, automation, and infrastructure implementations belong in their own repositories.

## Documentation

### AWS

* [AWS and Hybrid Disaster Recovery Guide](aws/disaster-recovery-aws-hybrid.md)
* [AWS Connectivity Options — Practical DevOps Reference](aws/aws-connectivity-options.md)
* [AWS Multi-Account Basics](aws/aws-multi-account-basics.md) — A beginner-friendly introduction to AWS multi-account architecture, account responsibilities, centralized access, security, logging and basic cross-account connectivity.

### Kubernetes

* [Kubernetes CNI Comparison](kubernetes/kubernetes-cni-comparison.md)
* [Kubernetes Internals](kubernetes/kubernetes-internals.md) — A practical walkthrough of Kubernetes internal workflows with diagrams for deployments, routing, rollouts, autoscaling, restarts, Vault injection, and GitOps.
* [Kubernetes Migration Checklist](kubernetes/kubernetes-migration-checklist.md)
* [Kubernetes Multi-Site DR](kubernetes/kubernetes-multi-site-dr.md) — An active-active multi-Region DR design on AWS with two EKS clusters, Argo CD GitOps, DynamoDB Global Tables, and global traffic routing.
* [Kubernetes Resource Sizing](kubernetes/kubernetes-resource-sizing.md)
* [Rancher 1.6 to AWS EKS Migration](kubernetes/rancher-1-6-to-aws-eks-migration.md)
* [FluxCD and Argo CD GitOps Basics](kubernetes/fluxcd-argocd-gitops.md) — A practical comparison of FluxCD and Argo CD, including GitOps fundamentals, reconciliation, Helm, Kustomize, drift correction, and troubleshooting.

### Terraform

* [Terraform State Separation in Large AWS Organizations](terraform/terraform-state-separation.md)
* [Breaking a Terraform Monolith into Independent State Components](terraform/terraform-monolith-decomposition.md)
* [Terraform and Terragrunt AWS Infrastructure Structure](terraform/terraform-terragrunt-aws-structure.md)

### Security

* [Secret Management Guide](security/secret-management-guide.md) — A practical guide to managing secrets with Ansible Vault, Terraform, AWS Secrets Manager, SSM Parameter Store, and HashiCorp Vault, including rekey vs rotation, CI/CD patterns, and common mistakes.
* [Security Compliance Quick Start](security/security-compliance-quick-start.md)

### CI/CD

* [CI/CD Standards](ci-cd/ci-cd-standards.md)

### Delivery and operations

* [ADR Template](delivery/adr-template.md)
* [AI-Assisted Development](delivery/ai-assisted-development.md)
* [Cloud Migration Risk Register](delivery/cloud-migration-risk-register.md)
* [Incident Response Runbook](delivery/incident-response-runbook.md)
* [Legacy Application Development](delivery/legacy-application-development.md)
* [Observability Checklist](delivery/observability-checklist.md)
* [Production Readiness Checklist](delivery/production-readiness-checklist.md)
* [Project Delivery Playbook](delivery/project-delivery-playbook.md)

## PDF conversion

See [PDF conversion tooling](tools/pdf-conversion/README.md).
