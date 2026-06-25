# Kubernetes Migration Checklist

This checklist provides a structured approach for migrating workloads into or between Kubernetes clusters.

## 1. Discovery & Scope

- [ ] Identify all application components (web, api, workers, cronjobs).
- [ ] Map all external dependencies (databases, cache, third-party APIs).
- [ ] Determine data migration requirements (volumes, databases).
- [ ] Audit current resource usage (CPU, Memory).
- [ ] Identify required Kubernetes versions and API compatibility.

## 2. Target State Design

- [ ] Select target cluster and region.
- [ ] Define Namespace structure and naming conventions.
- [ ] Design RBAC and Service Account requirements.
- [ ] Plan Network Policies (ingress/egress rules).
- [ ] Define Ingress/Egress controllers and DNS strategy.
- [ ] Design secret management strategy (External Secrets, Vault, etc.).

## 3. Workload Configuration

- [ ] Create/Update Deployment/StatefulSet manifests.
- [ ] Configure Resource Requests and Limits.
- [ ] Define Liveness, Readiness, and Startup probes.
- [ ] Configure Pod Disruption Budgets (PDBs).
- [ ] Set up HPA (Horizontal Pod Autoscaler) where applicable.
- [ ] Map ConfigMaps and Secrets.
- [ ] Configure initContainers for migrations or dependency checks.

## 4. Connectivity & Networking

- [ ] Configure Service objects (ClusterIP, NodePort, LoadBalancer).
- [ ] Set up Ingress resources and TLS certificates (cert-manager).
- [ ] Update DNS TTLs in preparation for cutover.
- [ ] Validate internal service discovery.
- [ ] Test firewall rules between cluster and external services.

## 5. Storage & State

- [ ] Provision Persistent Volumes (PVs) and Claims (PVCs).
- [ ] Validate storage classes and performance.
- [ ] Perform data migration/sync (Rsync, Velero, or application-level).
- [ ] Test volume mounting and permissions.

## 6. CI/CD & Automation

- [ ] Update build pipelines for new container registries.
- [ ] Configure deployment pipelines (Helm, Kustomize, ArgoCD, Flux).
- [ ] Set up environment-specific variables.
- [ ] Implement automated smoke tests for the new environment.

## 7. Observability & Validation

- [ ] Configure log shipping to central aggregator.
- [ ] Set up Prometheus/Grafana monitoring for new workloads.
- [ ] Configure alerts (Error rates, latency, saturation).
- [ ] Validate tracing spans (if applicable).
- [ ] Perform a load test to verify resource sizing.

## 8. Cutover & Rollback

- [ ] Define step-by-step cutover plan.
- [ ] Establish rollback triggers (e.g., >5% error rate).
- [ ] Coordinate with stakeholders for downtime windows (if needed).
- [ ] Execute DNS switch or Load Balancer cutover.
- [ ] Monitor logs and metrics intensely for the first 60 minutes.

## 9. Post-Migration Cleanup

- [ ] Hand over operational documentation to SRE/Ops.
- [ ] Update internal service registry.
- [ ] Decommission old infrastructure after soak period.
- [ ] Remove temporary migration tools/access.

> [!WARNING]
> Do not delete the old environment until the migrated workload is validated, monitored, and approved by the owning team. Ensure all data integrity checks are passed before shutting down legacy systems.
