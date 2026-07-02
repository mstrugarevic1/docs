# FluxCD and Argo CD GitOps Basics

This document explains what FluxCD and Argo CD are, why teams use them, and how to deploy a simple demo application with each tool.

The examples are intentionally small. They are for learning, local clusters, and basic platform discussions. They are not a production GitOps platform design.

## Table of Contents

- [1. What GitOps Means](#1-what-gitops-means)
- [2. Why Use FluxCD or Argo CD](#2-why-use-fluxcd-or-argo-cd)
- [3. FluxCD and Argo CD at a Glance](#3-fluxcd-and-argo-cd-at-a-glance)
- [4. Basic Repository Layout](#4-basic-repository-layout)
- [5. Demo Application Manifests](#5-demo-application-manifests)
- [6. Deploying the Demo App with FluxCD](#6-deploying-the-demo-app-with-fluxcd)
- [7. Deploying the Demo App with Argo CD](#7-deploying-the-demo-app-with-argo-cd)
- [8. Day-to-Day Usage](#8-day-to-day-usage)
- [9. Common Troubleshooting Commands](#9-common-troubleshooting-commands)
- [10. Practical Recommendations](#10-practical-recommendations)
- [11. References](#11-references)

## 1. What GitOps Means

GitOps means the desired state of the system is stored in Git. A controller running inside Kubernetes watches Git and makes the cluster match what is declared there.

Basic flow:

```text
Developer
  -> Pull request
  -> Git repository
  -> GitOps controller
  -> Kubernetes cluster
```

The pipeline usually builds and pushes the container image. GitOps then deploys the Kubernetes manifests, Helm release, or Kustomize overlay that references that image.

Git becomes the operational source of truth:

- What should run
- Which namespace it should run in
- Which image version should be deployed
- Which Helm chart or Kustomize overlay should be applied
- Who changed the desired state and when

## 2. Why Use FluxCD or Argo CD

Without GitOps, many teams deploy directly from CI pipelines using broad cluster credentials. That works for small setups, but it becomes harder to audit and recover.

GitOps helps because:

- Changes are reviewed through pull requests.
- The desired cluster state is visible in Git.
- Clusters continuously reconcile to the declared state.
- Drift can be detected and corrected.
- CI does not need long-lived admin access to every cluster.
- Rollback can be a Git revert.

GitOps does not replace CI. CI still builds, tests, scans, and publishes artifacts. GitOps handles the deployment reconciliation.

```text
CI:
Build image -> Test -> Push image

GitOps:
Watch Git -> Apply manifests -> Keep cluster in sync
```

## 3. FluxCD and Argo CD at a Glance

| Tool | Common style | Strengths | Typical fit |
| --- | --- | --- | --- |
| FluxCD | Kubernetes-native controllers and custom resources | Lightweight, automation-friendly, works well with pure Git workflows | Platform teams that prefer declarative CRDs and CLI-driven workflows |
| Argo CD | Controller plus web UI and CLI | Strong visual UI, app health view, easy manual sync controls | Teams that want a clear dashboard for application delivery |

Both tools can deploy plain YAML, Kustomize, and Helm. Both run inside Kubernetes and reconcile the cluster from Git.

High-level difference:

```text
FluxCD:
GitRepository + Kustomization/HelmRelease -> applied by controllers

Argo CD:
Application -> points to repo/path/chart -> applied by Argo CD
```

Use FluxCD when the team wants a small controller model and is comfortable operating mostly from Git and CLI. Use Argo CD when the team benefits from a UI showing application health, sync state, and deployment history.

## 4. Basic Repository Layout

Start with a simple layout. Do not create a large hierarchy before there are real environments and teams.

```text
gitops-repo
├── apps
│   └── dummy-app
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       └── service.yaml
└── clusters
    └── local
        ├── flux-dummy-app.yaml
        └── argo-dummy-app.yaml
```

Meaning:

- `apps/dummy-app` contains the application manifests.
- `clusters/local` contains the GitOps tool configuration for one cluster.
- More clusters can be added later as `clusters/dev`, `clusters/staging`, or `clusters/prod`.

For a demo, one repository is enough. For production, teams often separate application source code from deployment configuration.

## 5. Demo Application Manifests

Create a small app under `apps/dummy-app`.

`apps/dummy-app/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dummy-app
```

`apps/dummy-app/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dummy-app
  namespace: dummy-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dummy-app
  template:
    metadata:
      labels:
        app: dummy-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
```

`apps/dummy-app/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: dummy-app
  namespace: dummy-app
spec:
  selector:
    app: dummy-app
  ports:
    - port: 80
      targetPort: 80
```

`apps/dummy-app/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

Validate before committing:

```bash
kubectl kustomize apps/dummy-app
```

Commit and push these files before pointing FluxCD or Argo CD at the path.

## 6. Deploying the Demo App with FluxCD

FluxCD is commonly bootstrapped with the `flux` CLI. Bootstrap installs the Flux controllers and configures them to watch a repository path.

Example bootstrap:

```bash
export GITHUB_TOKEN=<token>
export GITHUB_USER=<github-user>

flux check --pre

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=gitops-repo \
  --branch=main \
  --path=./clusters/local \
  --personal
```

After bootstrap, define a Git source and a Kustomization. In many setups bootstrap already creates the cluster-level source. The example below shows the basic objects explicitly.

`clusters/local/flux-dummy-app.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: gitops-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/example-org/gitops-repo.git
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: dummy-app
  namespace: flux-system
spec:
  interval: 1m
  path: ./apps/dummy-app
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-repo
  timeout: 2m
  wait: true
```

Apply it once, or commit it under the bootstrap path so Flux applies it:

```bash
kubectl apply -f clusters/local/flux-dummy-app.yaml
```

Check status:

```bash
flux get sources git
flux get kustomizations
kubectl -n dummy-app get deploy,svc,pods
```

Force a reconciliation during testing:

```bash
flux reconcile source git gitops-repo -n flux-system
flux reconcile kustomization dummy-app -n flux-system
```

For a private repository, configure deploy keys or a Git secret instead of embedding credentials in manifests.

## 7. Deploying the Demo App with Argo CD

Argo CD is usually installed into the `argocd` namespace. The official quick-start install is enough for a local demo.

Install Argo CD:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
```

For local access to the UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Argo CD deploys applications using an `Application` object.

`clusters/local/argo-dummy-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dummy-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/example-org/gitops-repo.git
    targetRevision: main
    path: apps/dummy-app
  destination:
    server: https://kubernetes.default.svc
    namespace: dummy-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply the application:

```bash
kubectl apply -f clusters/local/argo-dummy-app.yaml
```

Check status:

```bash
kubectl -n argocd get applications
kubectl -n argocd describe application dummy-app
kubectl -n dummy-app get deploy,svc,pods
```

If using the Argo CD CLI:

```bash
argocd app get dummy-app
argocd app sync dummy-app
argocd app logs dummy-app
```

The UI shows sync status, health status, Kubernetes resources, events, and diffs between Git and the cluster.

## 8. Day-to-Day Usage

Normal change flow:

1. Update Kubernetes YAML, Kustomize, or Helm values in Git.
2. Open a pull request.
3. Review and merge.
4. FluxCD or Argo CD detects the change.
5. The cluster reconciles to the new desired state.
6. Verify pod health, service behavior, logs, and metrics.

Common examples:

| Change | Git change |
| --- | --- |
| Deploy a new image | Update `image:` tag or Helm values |
| Scale a demo app | Change `replicas` |
| Add a service | Add a `Service` manifest |
| Add config | Add a `ConfigMap` or external secret reference |
| Roll back | Revert the Git commit |

Do not store secrets directly in Git. Use a secret management pattern such as External Secrets, SOPS, Sealed Secrets, or a cloud secret manager integration.

## 9. Common Troubleshooting Commands

FluxCD:

```bash
flux get all -A
flux logs --all-namespaces
kubectl -n flux-system get pods
kubectl -n flux-system describe gitrepository <name>
kubectl -n flux-system describe kustomization <name>
```

Argo CD:

```bash
kubectl -n argocd get pods
kubectl -n argocd get applications
kubectl -n argocd describe application <name>
kubectl -n argocd logs deployment/argocd-application-controller
```

Application:

```bash
kubectl -n dummy-app get deploy,svc,pods
kubectl -n dummy-app describe pod <pod-name>
kubectl -n dummy-app logs deploy/dummy-app
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

Useful checks:

- Can the controller reach the Git repository?
- Is the path correct?
- Is the branch correct?
- Does `kubectl kustomize <path>` render locally?
- Does the image exist and support the cluster CPU architecture?
- Are namespace, RBAC, and admission policies blocking the deployment?

## 10. Practical Recommendations

- Start with one demo app and one cluster path.
- Keep app manifests small and readable.
- Prefer pull requests over direct pushes to deployment branches.
- Keep CI responsible for building images and GitOps responsible for deployment.
- Use private repo access through deploy keys, GitHub Apps, or scoped tokens.
- Do not give CI broad Kubernetes admin credentials unless there is a clear reason.
- Do not enable auto-prune on important environments until the team understands the blast radius.
- Use Argo CD UI or Flux status commands during onboarding so people can see reconciliation.
- Add production patterns later: SSO, RBAC, notifications, progressive delivery, image automation, policy checks, and secret management.

Simple choice:

```text
Want a strong UI for app status and manual sync? Start with Argo CD.
Want a controller-first GitOps toolkit with small CRDs? Start with FluxCD.
```

Both are valid. Pick the one your team will operate well.

## 11. References

- [FluxCD Get Started](https://fluxcd.io/flux/get-started/)
- [FluxCD GitRepository](https://fluxcd.io/flux/components/source/gitrepositories/)
- [FluxCD Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/)
- [Argo CD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Argo CD Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
