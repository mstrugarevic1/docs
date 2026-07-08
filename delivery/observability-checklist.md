# Observability Checklist

This checklist ensures that a service provides enough visibility to understand its behavior during normal operation and incidents.

## Table of Contents

* [1. Why we measure service levels](#1-why-we-measure-service-levels)
* [2. Logs](#2-logs)
* [3. Metrics (Golden Signals)](#3-metrics-golden-signals)
* [4. Traces](#4-traces)
* [5. Dashboards](#5-dashboards)
* [6. Alerts](#6-alerts)
* [7. Kubernetes-Specific Checks](#7-kubernetes-specific-checks)
* [8. SLOs & Operational Ownership](#8-slos--operational-ownership)
* [Example Grafana Dashboard](#example-grafana-dashboard)

## 1. Why we measure service levels

SRE teams measure the actual behavior experienced by service users to ensure reliability and manage error budgets.

* **SLI (Service Level Indicator):** The actual measured value of a service's behavior at a specific point in time (e.g., the percentage of valid requests completed successfully).
* **SLO (Service Level Objective):** An internal reliability target that the team aims to meet (e.g., 99.9% availability).
* **SLA (Service Level Agreement):** A contractual commitment made to customers. It often includes financial or contractual consequences when the commitment is not met.

**Key Principles:**

* The SLO should normally be stricter than the SLA so that engineering teams can react before a contractual breach occurs.
* Measuring the SLI allows the organization to determine whether users are receiving the service level guaranteed by the contract.
* SLOs are used for error-budget decisions and reliability-focused alerting.
* An SLA is not a separate application metric; the measured SLI is compared against both SLO and SLA thresholds.

**Measurement Requirements:**

Every measurement must have a clearly defined:
* **Time window:** The period over which the SLI is calculated (e.g., rolling 30 days).
* **Request scope:** Which requests are included (e.g., all public API calls).
* **Success criteria:** What constitutes a successful request (e.g., HTTP 2xx).
* **Failure criteria:** What constitutes a failed request (e.g., HTTP 5xx).
* **Exclusions:** What is explicitly left out (e.g., maintenance windows, 4xx client errors).

**Example:**
* SLI: percentage of valid requests completed successfully
* SLO: 99.9%
* SLA: 99.5%
* Error budget: 0.1%

*Note: The [SLO Demo](../../k8s-examples/slo-demo/README.md) uses a short dashboard window so that results are visible quickly, while a production SLA would normally be evaluated over a longer period.*

## 2. Logs
- [ ] Logs are structured (JSON) for easy parsing.
- [ ] Correlation IDs are included for cross-service requests.
- [ ] Logs are forwarded to a central log management system.

## 3. Metrics (Golden Signals)
- [ ] **Latency:** Time it takes to service a request.
- [ ] **Traffic:** Demand placed on the system.
- [ ] **Errors:** The rate of requests that fail.
- [ ] **Saturation:** How "full" is the service.

## 4. Traces
- [ ] Distributed tracing is implemented for microservices.
- [ ] Trace IDs are propagated through all service boundaries.

## 5. Dashboards
- [ ] High-level service overview dashboard exists.
- [ ] Operational dashboards are linked from runbooks.

## 6. Alerts
- [ ] Alerts are actionable (not "just FYI").
- [ ] Thresholds are based on SLOs.
- [ ] Severity levels are defined (Page vs. Ticket).

## 7. Kubernetes-Specific Checks
- [ ] **Pod Restarts:** Alert on frequent container restarts.
- [ ] **OOMKilled:** Monitor for memory-related crashes.
- [ ] **CPU Throttling:** Track if CPU limits are causing latency.
- [ ] **Node Pressure:** Monitor node health (Disk/Memory pressure).
- [ ] **HPA Behavior:** Ensure horizontal scaling is triggering as expected.

## 8. SLOs & Operational Ownership
- [ ] SLIs/SLOs are clearly defined and measurable.
- [ ] Alert routing is configured to the owning team.

See the [Kubernetes SLO Demo](../../k8s-examples/slo-demo/README.md) for a practical implementation.

> [!IMPORTANT]
> Observability is not only about collecting data. It is about making the system understandable during normal operation and incidents.

## Example Grafana Dashboard

<!-- Add the real screenshot after the demo is running:
![SLO Demo Grafana Dashboard](images/slo-demo-grafana-dashboard.png)
-->
