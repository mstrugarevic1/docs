# Kubernetes Workload Sizing with Goldilocks

## Introduction

### Purpose
This document provides a practical framework for optimizing Kubernetes resource allocation. The goal is to move away from "guessing" resource needs and instead use data-driven recommendations to ensure application stability, reliability, and cost efficiency.

### Audience
*   **Platform Engineers:** To establish cluster-wide sizing standards and resource quotas.
*   **DevOps/SRE:** To automate and monitor resource efficiency and prevent capacity-related outages.
*   **Application Developers:** To understand the resource footprint of their services.
*   **FinOps:** To identify and eliminate "cloud slack" (paid but unused resources).

### Why Proper Sizing Matters
A properly sized cluster avoids the "Goldilocks Problem":
1.  **Too Small:** Leads to CPU throttling (latency) or `OOMKilled` events (crashes).
2.  **Too Large:** Leads to massive cloud waste and inefficient node utilization.
3.  **Just Right:** Ensures performance during peaks while minimizing operational costs.

### What is Goldilocks?
Goldilocks is an open-source tool that creates Vertical Pod Autoscaler (VPA) objects in "Recommendation Mode." It monitors real-time CPU and Memory usage and provides suggested `requests` and `limits` via a simple web dashboard.

---

## Resource Fundamentals

| Concept | Purpose | Over-provisioned | Under-provisioned |
| :--- | :--- | :--- | :--- |
| Requests | Scheduling and resource reservation | Wasted cost / unused capacity | Resource contention and unstable performance |
| Limits | Hard resource ceiling | Can cause inefficient allocation if too high | OOMKilled for memory / CPU throttling for CPU |

---

## Installation (via Helm)

### 1. Prerequisite: Vertical Pod Autoscaler (VPA)
Goldilocks relies on the VPA Recommender engine to perform historical analysis.

> [!IMPORTANT]
> VPA must be installed first as it provides the background analysis engine. This installation includes the Recommender, Admission Controller, and Updater components.

```bash
# Add the Fairwinds repository
helm repo add fairwinds-stable https://charts.fairwinds.com/stable

# Install VPA
helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace
```

### 2. Goldilocks Controller & Dashboard
The Goldilocks controller watches for labeled namespaces, while the dashboard provides the visualization of recommendations.

```bash
# Install Goldilocks into its own namespace
helm install goldilocks fairwinds-stable/goldilocks --namespace goldilocks --create-namespace
```

---

## Usage Workflow

### 1. Enable Analysis
Analysis is "opt-in" per namespace. This ensures you only track relevant workloads and avoid unnecessary overhead on system components.

```bash
kubectl label ns <namespace> goldilocks.fairwinds.com/enabled=true
```

> [!NOTE]
> Once labeled, VPA objects are automatically created for all Deployments in that namespace in `Off` mode, meaning no changes are made to your running Pods.

### 2. Wait for Data (Burn-in Period)
Recommendations are not instant. The VPA engine needs to capture representative traffic patterns to provide meaningful output.

*   **Minimum:** 1 hour (use only for initial rough estimates in non-production).
*   **Recommended:** **24 to 48 hours** to capture full daily traffic cycles and background jobs.
*   **Ideal:** 7 days to capture weekly cycles (e.g., weekend vs. weekday patterns).

### 3. View Recommendations
Access the local dashboard to review the suggestions.

```bash
# Forward the service to your local machine
kubectl -n goldilocks port-forward svc/goldilocks-dashboard 8080:80
```

Open `http://localhost:8080` to review the two primary modes: **Guaranteed** and **Burstable**.

---

## Sizing Strategies

### QoS Classes
*   **Guaranteed:** Set `Requests == Limits`. This ensures the Pod is in the highest Quality of Service (QoS) class, making it the last to be evicted during node pressure.
*   **Burstable:** Set `Requests < Limits`. This allows the application to "burst" into spare node capacity during spikes while keeping baseline resource reservation low.

> [!NOTE]
> Guaranteed QoS can be useful for critical workloads, but `requests == limits` should not be applied blindly.
> For latency-sensitive services, CPU limits should be reviewed carefully because they can introduce throttling.
> Memory limits are usually more important because exceeding memory limits results in `OOMKilled` containers.

### The 20% Buffer
As a general rule of thumb, add a ~20% safety margin to the "Maximum Observed" recommendation to handle unexpected traffic micro-bursts or startup spikes that the VPA might have smoothed over.

---

> [!WARNING]
> Goldilocks recommendations should not be applied automatically to production workloads.
> Treat them as input for review, not as final values.
> Always validate recommendations against real traffic patterns, load tests, incidents, and business-critical behavior.

---

## Recommended Review Process

1.  Enable Goldilocks on a selected namespace.
2.  Wait for enough usage data (at least 24-48 hours).
3.  Compare recommendations with current requests and limits.
4.  Review CPU and memory separately.
5.  Check historical incidents, `OOMKilled` events, and CPU throttling.
6.  Apply changes through a pull request.
7.  Deploy gradually (canary or blue/green).
8.  Monitor latency, restarts, CPU throttling, memory usage, and node pressure.

---

## After Applying Resource Changes

Monitor:
- Pod restarts
- `OOMKilled` events
- CPU throttling
- Memory usage
- Latency
- Error rate
- Node pressure
- HPA behavior

---

## Do Not Use Blindly

Goldilocks is an excellent starting point for resource recommendations, but it does not understand every application behavior or external constraint.

Be careful with:
*   Workloads with rare or extreme traffic spikes.
*   Batch jobs and CronJobs with short runtimes.
*   Memory-leaking applications.
*   Applications with significant "cold start" resource spikes.
*   Latency-sensitive services where any throttling is unacceptable.
*   Workloads with incomplete traffic or maintenance windows during the observation period.

---

## Leadership Perspectives

### QA Perspective
> The "burn-in" period is critical. For performance testing, ensure Goldilocks runs during a full load test cycle to capture true peak memory usage, which is often missed during idle or low-traffic states.

### Staff Engineer Perspective
> This guide addresses the "ROI of Efficiency." By bridging the gap between developers and FinOps, we create a sustainable growth model where scaling doesn't linearly increase costs while maintaining system reliability.

### Platform/Cloud Engineer Perspective
> The use of Helm for VPA and Goldilocks ensures version control and easy updates. Labeling namespaces is a low-friction way to roll this out across a multi-tenant cluster without affecting system performance or stability.
