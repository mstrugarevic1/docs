# Cloud Docs

Practical engineering guides and checklists for cloud, platform, DevOps, SRE, and delivery work.

This repository contains documentation only. Code, automation, and infrastructure examples belong in their own repositories.

## Documentation

* [AWS and Hybrid Disaster Recovery Guide](disaster-recovery-aws-hybrid.md)
* [AWS Connectivity Options — Practical DevOps Reference](aws-connectivity-options.md)
* [ADR Template](adr-template.md)
* [AI-Assisted Development](ai-assisted-development.md)
* [CI/CD Standards](ci-cd-standards.md)
* [Cloud Migration Risk Register](cloud-migration-risk-register.md)
* [Incident Response Runbook](incident-response-runbook.md)
* [Kubernetes CNI Comparison](kubernetes-cni-comparison.md)
* [Kubernetes Migration Checklist](kubernetes-migration-checklist.md)
* [Kubernetes Resource Sizing](kubernetes-resource-sizing.md)
* [Legacy Application Development](legacy-application-development.md)
* [Observability Checklist](observability-checklist.md)
* [Production Readiness Checklist](production-readiness-checklist.md)
* [Project Delivery Playbook](project-delivery-playbook.md)
* [Rancher 1.6 to AWS EKS Migration](rancher-1-6-to-aws-eks-migration.md)
* [Security Compliance Quick Start](security-compliance-quick-start.md)
* [Terraform State Separation in Large AWS Organizations](terraform-state-separation.md)
* [Terraform and Terragrunt AWS Infrastructure Structure](terraform-terragrunt-aws-structure.md)

## PDF conversion

Use `convert-to-pdf.sh` to render the Markdown documents in this repository to PDF files.

```bash
./convert-to-pdf.sh
```

The script writes PDFs to `pdf/` by default. To use a different output directory, pass it as the first argument:

```bash
./convert-to-pdf.sh output-dir
```

The conversion uses `npx md-to-pdf`, which renders through Chromium. The script applies repository-specific CSS for readable browser-style PDFs, including Arial/Helvetica body text, Menlo code blocks, and visible table borders.
