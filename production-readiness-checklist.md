# Production Readiness Checklist

This checklist validates whether a service is technically and operationally ready for production traffic.

## 1. Ownership & Governance

- [ ] **[Critical]** Primary and secondary owner/team defined.
- [ ] **[Critical]** Service description and business impact documented.
- [ ] **[Recommended]** Architecture diagram available and updated.
- [ ] **[Critical]** On-call rotation established and communicated.
- [ ] **[Critical]** Operational runbook exists (common issues, mitigation).

## 2. Deployment & Configuration

- [ ] **[Critical]** CI/CD pipeline is fully automated and tested.
- [ ] **[Recommended]** Environment promotion path (Dev -> Staging -> Prod) is clear.
- [ ] **[Critical]** Rollback process is documented and tested.
- [ ] **[Critical]** Secrets are managed securely (not in Git or plain-text vars).
- [ ] **[Recommended]** ConfigMaps handle environment-specific overrides.

## 3. Reliability & Scaling

- [ ] **[Critical]** Resource Requests and Limits are configured based on usage data.
- [ ] **[Recommended]** Horizontal Pod Autoscaler (HPA) is configured and tested.
- [ ] **[Optional]** Pod Disruption Budgets (PDBs) are defined.
- [ ] **[Critical]** Health checks (Liveness, Readiness, Startup) are correctly configured.
- [ ] **[Recommended]** Retry logic and circuit breakers are implemented for dependencies.

## 4. Observability

- [ ] **[Critical]** Logs are structured (JSON) and forwarded to a central system.
- [ ] **[Critical]** Key metrics (Golden Signals: Latency, Traffic, Errors, Saturation) are tracked.
- [ ] **[Critical]** Critical alerts have defined thresholds and clear routing.
- [ ] **[Recommended]** Service dashboard exists in the central observability tool.
- [ ] **[Recommended]** SLOs (Service Level Objectives) are defined and measurable.

## 5. Data & State

- [ ] **[Critical]** Database backups are scheduled and tested for restoration.
- [ ] **[Recommended]** Data retention policies are implemented.
- [ ] **[Critical]** Database migrations are handled as part of the deployment.
- [ ] **[Recommended]** Persistent storage performance meets requirements.

## 6. Security & Compliance

- [ ] **[Critical]** RBAC follows the principle of least privilege.
- [ ] **[Recommended]** Network Policies restrict traffic to required ports/services.
- [ ] **[Recommended]** Vulnerability scanning is integrated into the build process.
- [ ] **[Critical]** Compliance requirements (GDPR, SOC2, etc.) are validated.

## 7. Incident Response

- [ ] **[Critical]** Escalation path is documented in the runbook.
- [ ] **[Recommended]** Stakeholders are identified for communication.
- [ ] **[Recommended]** Post-incident review process is understood by the team.

## Go / No-Go Criteria

*   **Go:** All **[Critical]** items are checked, and no major issues were found in Staging.
*   **No-Go:** Any **[Critical]** item is missing or a high-impact bug is identified.

---

> [!WARNING]
> A service is not production-ready just because it was deployed successfully.
> It must be observable, supportable, documented, and owned.
