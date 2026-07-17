# Rancher 1.6 Cattle to Amazon EKS Migration

This guide is for migrating workloads from Rancher 1.6 **Cattle** to Amazon EKS. It is not about Rancher-managed Kubernetes clusters.

Rancher 1.6 Cattle used Docker hosts, stacks, services, `docker-compose.yml`, `rancher-compose.yml`, Rancher load balancers, service links, sidekicks, and `io.rancher.*` labels. EKS expects Kubernetes resources, explicit networking, explicit storage, and deployment state stored outside the Rancher UI.

## 1. Migration Shape

Do not start by writing Helm charts. Start by converting one real Rancher stack into plain Kubernetes manifests, proving that it runs on EKS, and only then package it.

Recommended order:

1. Inventory the Rancher stack.
2. Convert one service at a time to Kubernetes.
3. Replace Rancher-only behavior with Kubernetes-native behavior.
4. Run the workload on EKS with test traffic.
5. Add Helm, Kustomize, or Argo CD after the manifest shape is proven.
6. Cut over traffic only after rollback has been tested.

## 2. Inventory Each Rancher Stack

Capture the behavior that Rancher was hiding. Most migration problems come from missing one of these items.

| Item | What to capture | EKS target |
|---|---|---|
| Image | Registry, tag, pull policy | ECR or approved registry |
| Ports | Container ports and published ports | `Service`, `Ingress`, or `LoadBalancer` |
| Environment | Non-secret env vars | `ConfigMap` or Helm values |
| Secrets | Passwords, API keys, certificates | External Secrets, AWS Secrets Manager, or Kubernetes `Secret` |
| Volumes | Host paths, named volumes, shared mounts | EBS, EFS, or application redesign |
| Health checks | Rancher health check path, port, interval | Readiness, liveness, startup probes |
| Links | `links`, service aliases, hardcoded names | Kubernetes `Service` DNS |
| Sidekicks | Containers coupled to the main service | Same Pod or separate workload |
| Scheduling | `io.rancher.scheduler.*` labels | Node selectors, affinity, taints |
| Load balancer | Rancher LB rules and hostnames | AWS Load Balancer Controller and Ingress |

Keep the inventory per stack. A single global spreadsheet becomes stale quickly.

## 3. Rancher to Kubernetes Mapping

| Rancher 1.6 Cattle | Kubernetes / AWS |
|---|---|
| Environment | EKS cluster, account, or namespace boundary |
| Stack | Namespace, Helm release, or Argo CD Application |
| Service | Deployment, StatefulSet, DaemonSet, CronJob, or Job |
| Scale | `replicas` or HPA |
| Rancher LB | Ingress, ALB, NLB, or Service `LoadBalancer` |
| Health check | Readiness, liveness, and startup probes |
| Service link | Kubernetes Service DNS |
| Sidekick | Multi-container Pod when lifecycle is shared |
| Host volume | PVC backed by EBS/EFS, or remove the host dependency |
| Rancher catalog | Helm chart only if reuse is needed |

## 4. Convert One Service

Start with the smallest stateless service that has an HTTP health check and no persistent volume. This proves the platform path without mixing in state migration.

### Rancher Source

`docker-compose.yml`:

```yaml
version: "2"
services:
  web:
    image: registry.example.com/web:v1.8.3
    environment:
      LOG_LEVEL: info
      API_URL: http://api:8080
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:host_label: role=frontend
    ports:
      - "8080"
```

`rancher-compose.yml`:

```yaml
version: "2"
services:
  web:
    scale: 2
    health_check:
      port: 8080
      request_line: GET /health HTTP/1.0
      interval: 2000
      response_timeout: 2000
      unhealthy_threshold: 3
      healthy_threshold: 2
```

### Kubernetes Target

`ConfigMap`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  namespace: web
data:
  LOG_LEVEL: info
  API_URL: http://api.web.svc.cluster.local:8080
```

`Deployment`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      nodeSelector:
        role: frontend
      containers:
        - name: web
          image: <aws-account-id>.dkr.ecr.<region>.amazonaws.com/web:v1.8.3
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: web-config
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            periodSeconds: 10
            failureThreshold: 3
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              memory: 256Mi
```

`Service`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: web
spec:
  selector:
    app: web
  ports:
    - name: http
      port: 80
      targetPort: 8080
```

`Ingress` using AWS Load Balancer Controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: web
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: web.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

## 5. Rancher-Specific Gotchas

### Service Links

Rancher service links often create assumptions about names, aliases, and startup order. Kubernetes DNS gives stable service names, but it does not wait for dependencies to be ready.

Fix this in the application where possible. Use retries, timeouts, and readiness checks. Use init containers only for narrow dependency checks; they are not a replacement for application resilience.

### Sidekicks

Move a sidekick into the same Pod only when it must share lifecycle, localhost, or a volume with the main container.

Use a separate Deployment when the sidekick can scale, restart, or deploy independently. Do not preserve the sidekick pattern just because Rancher used it.

### Rancher Load Balancers

Rancher HAProxy rules do not map one-to-one to ALB annotations. Capture host rules, paths, ports, TLS behavior, redirects, and health checks before writing Ingress resources.

Validate ALB behavior with real requests before DNS cutover.

### Host Volumes

Host mounts are usually the hardest part of the migration. EKS nodes are replaceable; data should not depend on a specific node filesystem.

Use EBS for single-writer block storage, EFS for shared filesystem needs, or move state to a managed service. Avoid `hostPath` except for infrastructure agents.

### Scheduling Labels

Rancher host labels can become `nodeSelector` or node affinity. Keep the rule only if the workload really needs it. Many old placement rules exist because of historical host layout, not because the application requires it.

## 6. EKS Baseline Before Workload Migration

Have these pieces ready before moving application traffic:

* EKS cluster and node groups sized for the migrated workload.
* ECR repository or approved external registry access.
* AWS Load Balancer Controller for Ingress or `LoadBalancer` Services.
* StorageClass choices for EBS and EFS if the workload uses volumes.
* External Secrets or another secret-management workflow.
* Logging and metrics collection.
* Namespace, RBAC, resource quota, and limit range standards.
* DNS and certificate process for cutover.

Do not block the first workload on a perfect platform. Block it only on the parts that workload actually needs.

## 7. Packaging and GitOps

Keep raw Kubernetes manifests until the conversion is proven. Then choose the smallest packaging model that fits:

* Use plain Kustomize when the service only needs environment patches.
* Use Helm when the application needs reusable templating or many deploy-time values.
* Use Argo CD to reconcile the final desired state from Git.

Avoid wrapping every migrated service in both Helm and Kustomize unless there is a real environment or ownership reason.

Example repository shape:

```text
apps/
  web/
    base/
      deployment.yaml
      service.yaml
      ingress.yaml
      kustomization.yaml
    overlays/
      dev/
      prod/
clusters/
  prod/
    web.yaml   # Argo CD Application
```

## 8. Validation Workflow

For each workload:

1. Render manifests locally.
2. Run server-side dry run against the target cluster.
3. Deploy to a non-production namespace.
4. Confirm pods become ready and stay ready.
5. Test Service DNS from another Pod.
6. Test Ingress or LoadBalancer with the expected hostname and path.
7. Confirm config and secrets are injected without exposing secret values.
8. Restart pods and nodes where practical to check recovery.
9. Run application smoke tests against EKS.

Useful commands:

```bash
kubectl kustomize apps/web/overlays/dev
kubectl apply --dry-run=server -f rendered.yaml
kubectl -n web get deploy,rs,pod,svc,ingress
kubectl -n web describe pod -l app=web
kubectl -n web logs deploy/web
```

## 9. Cutover and Rollback

Before cutover, decide what rollback actually means for this workload.

Traffic-only rollback is possible when:

* the Rancher version is still running;
* no incompatible database migration has happened;
* both versions can process the same messages and API calls;
* DNS or load balancer changes can be reversed quickly.

Rollback is harder when the migration changes storage, queue consumers, database schema, or external integrations.

Minimum cutover plan:

1. Freeze Rancher-side deployment changes.
2. Deploy the EKS workload from Git.
3. Run smoke tests against the EKS endpoint.
4. Lower DNS TTL before migration if DNS is the cutover mechanism.
5. Shift traffic.
6. Watch errors, latency, pod restarts, and application logs.
7. Keep the Rancher workload available until the stabilization window passes.

Minimum rollback plan:

1. Stop traffic to EKS.
2. Point DNS or load balancer rules back to Rancher.
3. Stop EKS consumers if duplicate processing is possible.
4. Revert Git only after traffic is safe.
5. Review data changes before retrying the migration.

## 10. Completion Criteria

The workload is migrated when:

* production traffic is served from EKS;
* Rancher-specific labels, links, and load balancer rules are no longer required;
* config and secrets are managed outside the Rancher UI;
* manifests are stored in Git and reconciled by the chosen deployment workflow;
* monitoring, logs, probes, and rollback steps have been tested;
* the old Rancher service is removed after the stabilization period.
