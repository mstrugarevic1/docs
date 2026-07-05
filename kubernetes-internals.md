# Kubernetes Internals

## Introduction

Most Kubernetes tutorials focus on *how* to deploy applications. They teach Deployments, Services, Ingresses and Helm charts.

Much fewer explain **what actually happens inside Kubernetes** after you execute:

```bash
kubectl apply -f deployment.yaml
```

or how a request travels from a user's browser all the way to your application.

This document focuses on those internal workflows.

It is intended for:

- DevOps Engineers
- Platform Engineers
- Site Reliability Engineers (SRE)
- Cloud Engineers
- Engineers preparing for Kubernetes interviews
- Anyone who wants to understand how Kubernetes works internally instead of treating it as a black box.

The document assumes basic Kubernetes knowledge.

It intentionally avoids advanced kernel implementation details and instead explains the interactions between Kubernetes components that engineers work with every day.

---

# Kubernetes Architecture

Before diving into individual components, it is useful to understand that Kubernetes is composed of two logical parts.

```
+----------------------+
|   Control Plane      |
+----------------------+

          |

+----------------------+
|    Worker Nodes      |
+----------------------+
```

The Control Plane is responsible for making decisions.

Worker Nodes are responsible for executing those decisions.

The API Server acts as the central communication hub.

Almost every Kubernetes component communicates with the API Server rather than talking directly to each other.

---

# Control Plane Components

## API Server

The API Server is the central component of Kubernetes.

Every operation performed against the cluster eventually reaches the API Server.

Examples:

- kubectl apply
- kubectl delete
- ArgoCD synchronization
- Helm installation
- Controller updates
- Scheduler bindings
- kubelet status updates

The API Server is responsible for:

- Authentication
- Authorization
- Admission Controllers
- Validation
- Persisting objects into etcd

Think of it as the front door of the cluster.

Nothing enters Kubernetes without passing through the API Server.

> Screenshot placeholder

---

## etcd

etcd is the distributed key-value database that stores the desired state of the cluster.

Examples of stored objects:

- Pods
- Deployments
- Services
- ConfigMaps
- Secrets
- Nodes
- ReplicaSets

etcd does **not** run containers.

It only stores cluster state.

If etcd is unavailable, the cluster loses its source of truth.

> Screenshot placeholder

---

## Scheduler

The Scheduler is responsible for selecting **where** a Pod should run.

It does **not** create Pods.

It does **not** start containers.

Its only responsibility is choosing the most appropriate node.

To make that decision it considers:

- CPU requests
- Memory requests
- Taints
- Tolerations
- Affinity
- Anti-affinity
- Available resources
- Scheduling policies

After selecting a node, it informs the API Server.

The kubelet on that node performs the actual work.

> Screenshot placeholder
