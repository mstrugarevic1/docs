# EKS Common Production Problems

This document is a short recognition guide for common problems that occur in and around Amazon EKS clusters.

It is not a troubleshooting guide, runbook, architecture recommendation, or disaster recovery plan. The goal is to help engineers quickly recognize the type of failure they may be looking at and the layer where it usually belongs.

## Table of Contents

- [1. Control Plane and API Access](#1-control-plane-and-api-access)
- [2. Node and Capacity Problems](#2-node-and-capacity-problems)
- [3. Pod Scheduling Problems](#3-pod-scheduling-problems)
- [4. Networking and CNI Problems](#4-networking-and-cni-problems)
- [5. Ingress and Load Balancer Problems](#5-ingress-and-load-balancer-problems)
- [6. DNS and Service Discovery Problems](#6-dns-and-service-discovery-problems)
- [7. Storage Problems](#7-storage-problems)
- [8. IAM and Permission Problems](#8-iam-and-permission-problems)
- [9. Add-on and Version Problems](#9-add-on-and-version-problems)
- [10. Workload Configuration Problems](#10-workload-configuration-problems)
- [11. Observability and Operational Blind Spots](#11-observability-and-operational-blind-spots)
- [12. Key Takeaways](#12-key-takeaways)

## 1. Control Plane and API Access

EKS manages the Kubernetes control plane, but workloads still depend on API Server availability, authentication, authorization, admission control, and client connectivity.

Common symptoms:

- `kubectl` and controllers become slow or fail intermittently.
- GitOps tools cannot apply manifests.
- Autoscalers, operators, or admission webhooks stop reconciling.
- New Pods, Services, or Ingress changes do not appear even though running workloads may continue.

Typical layer:

- EKS control plane, Kubernetes API access, IAM authentication, RBAC, admission webhooks, or network access to the API endpoint.

## 2. Node and Capacity Problems

Many production incidents are caused by worker node capacity rather than the managed control plane.

Common symptoms:

- Pods remain `Pending`.
- Existing Pods are evicted or restarted during node pressure.
- Deployments stall because new replicas cannot fit.
- Cluster Autoscaler or Karpenter adds nodes too slowly, chooses unsuitable instance types, or cannot scale because of cloud limits.

Typical layer:

- EC2 capacity, Auto Scaling groups, managed node groups, Karpenter, instance quotas, subnet capacity, or workload resource requests.

## 3. Pod Scheduling Problems

Scheduling failures often look like an application outage even when the cluster itself is healthy.

Common symptoms:

- New replicas are not assigned to nodes.
- Rollouts pause with old Pods still serving traffic.
- Pods cannot run because of taints, tolerations, affinity, topology spread, missing resources, or Pod Disruption Budgets.
- Critical workloads compete with batch or low-priority workloads.

Typical layer:

- Kubernetes scheduler, workload placement rules, resource requests, priority classes, and disruption policy.

## 4. Networking and CNI Problems

EKS commonly uses the Amazon VPC CNI, where Pods receive IP addresses from VPC subnets. This makes AWS network design part of cluster reliability.

Common symptoms:

- Pods cannot start because no Pod IP is available.
- Some nodes run workloads while others cannot attach more Pod networking.
- Pod-to-Pod or Pod-to-service traffic fails only in specific subnets or Availability Zones.
- NetworkPolicy behavior differs from expectations because the selected CNI or add-on does not enforce the intended policy.

Typical layer:

- Amazon VPC CNI, ENI limits, subnet IP exhaustion, routing, security groups, NetworkPolicy implementation, or node networking.

## 5. Ingress and Load Balancer Problems

External traffic depends on AWS infrastructure, Kubernetes resources, and controllers agreeing on desired state.

Common symptoms:

- DNS resolves but users receive 404, 502, 503, or timeouts.
- An Ingress exists but no load balancer is created.
- Load balancer targets are unhealthy even though Pods are running.
- TLS certificates, listener rules, or target groups do not match the intended application route.

Typical layer:

- AWS Load Balancer Controller, ALB/NLB configuration, Ingress rules, Services, EndpointSlices, Pod readiness, certificates, or DNS.

## 6. DNS and Service Discovery Problems

Kubernetes DNS issues can break applications even when Pods and Services are otherwise healthy.

Common symptoms:

- Applications fail to resolve internal service names.
- Failures appear as intermittent connection errors, startup failures, or dependency timeouts.
- CoreDNS becomes CPU constrained or overloaded during traffic spikes.
- External DNS records point to stale or unexpected load balancer names.

Typical layer:

- CoreDNS, cluster DNS configuration, ExternalDNS, Route 53 records, Service names, or application resolver behavior.

## 7. Storage Problems

Storage failures often appear during rollout, rescheduling, node replacement, or zone disruption.

Common symptoms:

- Stateful Pods remain stuck because volumes cannot attach or mount.
- A volume is bound in one Availability Zone while the Pod is scheduled in another.
- Applications start but fail because filesystem permissions, mount paths, or storage classes differ from expectations.
- EBS-backed workloads recover slower than stateless workloads after node loss.

Typical layer:

- EBS CSI driver, EFS CSI driver, StorageClass settings, PersistentVolumes, Availability Zone placement, attach limits, or application storage assumptions.

## 8. IAM and Permission Problems

EKS workloads commonly depend on AWS IAM through node roles, IRSA, or EKS Pod Identity. Permission failures can look like application bugs.

Common symptoms:

- Pods start successfully but cannot read S3, publish to SNS/SQS, fetch secrets, or call AWS APIs.
- Controllers cannot create cloud resources such as load balancers, volumes, DNS records, or certificates.
- Failures appear only after a service account, role, trust policy, or OIDC provider change.

Typical layer:

- IAM policies, trust relationships, service accounts, IRSA, EKS Pod Identity, controller permissions, or AWS service authorization.

## 9. Add-on and Version Problems

Managed add-ons reduce installation work, but they still have versions, compatibility rules, and operational behavior.

Common symptoms:

- CoreDNS, kube-proxy, VPC CNI, CSI drivers, or load balancer controllers behave differently after an upgrade.
- A Kubernetes version upgrade exposes deprecated APIs or incompatible manifests.
- One add-on is managed by EKS while another is managed by Helm or GitOps, causing ownership confusion.
- System Pods are healthy but running versions that no longer match the cluster version.

Typical layer:

- EKS managed add-ons, Helm-managed add-ons, Kubernetes version skew, API deprecations, controller compatibility, or ownership boundaries.

## 10. Workload Configuration Problems

Some EKS incidents are ordinary Kubernetes workload problems with AWS-specific impact.

Common symptoms:

- Rolling updates send traffic to Pods before the application is ready.
- Containers restart because memory limits are too low or startup probes are missing.
- HPA does not scale as expected because metrics are missing or requests are unrealistic.
- ConfigMap or Secret changes do not affect running Pods.

Typical layer:

- Deployment strategy, probes, resource requests and limits, autoscaling configuration, ConfigMaps, Secrets, and application startup behavior.

## 11. Observability and Operational Blind Spots

The hardest EKS problems are often not invisible; they are split across Kubernetes, AWS, and application telemetry.

Common symptoms:

- Kubernetes shows healthy Pods while the load balancer shows unhealthy targets.
- AWS metrics show network or capacity pressure that is not visible in application dashboards.
- Logs exist in several places but are not correlated by service, node, pod, request, or deployment.
- Operators can see the symptom but not the failing layer.

Typical layer:

- Metrics, logs, traces, events, AWS service telemetry, alert design, ownership boundaries, and incident workflow.

## 12. Key Takeaways

- EKS manages the control plane, not the full production system.
- Multi-AZ does not remove subnet, capacity, routing, storage, or application placement problems.
- Managed add-ons still need version and ownership management.
- Many EKS outages are caused by AWS dependencies around the cluster, not by Kubernetes alone.
- The fastest way to classify an incident is to identify the failing layer: control plane, node, scheduler, CNI, ingress, DNS, storage, IAM, add-on, workload, or observability.
