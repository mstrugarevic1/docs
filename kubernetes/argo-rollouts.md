# Argo Rollouts

## Overview

Argo Rollouts is a Kubernetes controller and a set of custom resources for progressive delivery. It extends Kubernetes with rollout strategies that are more controlled than the standard `Deployment` rolling update.

The main `Rollout` resource is an alternative to a Kubernetes `Deployment`. Like a Deployment, it creates and manages ReplicaSets from a Pod template. Unlike a standard Deployment, it can control how a new ReplicaSet becomes the stable application version through Blue/Green, Canary, pauses, analysis, experiments, and traffic routing.

Progressive delivery means releasing a change gradually and validating it before exposing all users to it. Kubernetes `RollingUpdate` is useful, but it mainly gates progress on pod availability and readiness. For sensitive production releases, that may not be enough. A pod can be ready while the application has functional, latency, error-rate, or business-level problems.

Argo Rollouts reduces this risk by controlling promotion from the old stable ReplicaSet to the new candidate ReplicaSet.

## The Problem It Solves

A standard Kubernetes rolling update gradually replaces old pods with new pods. Traffic usually continues through the same Kubernetes Service, and Kubernetes primarily evaluates whether pods are created, scheduled, running, and ready.

That is a narrow safety check. A new pod can pass readiness while returning incorrect responses, increasing latency, failing only on a subset of requests, or breaking a business workflow. Standard rolling updates also provide limited native support for staged traffic exposure, manual approval, metric-based promotion, or automated rollback based on external signals.

Progressive delivery reduces the blast radius. A new version can receive preview traffic, a small percentage of production traffic, or no production traffic until validation succeeds. Promotion can pause for human review or depend on metrics such as error rate, latency, availability, restart count, or successful transaction rate.

## Core Components

Required components:

* **Argo Rollouts controller** watches Rollout-related resources and reconciles ReplicaSets, Services, analysis, experiments, and traffic provider configuration.
* **`Rollout`** declares the workload and rollout strategy. It is the primary application resource managed by Argo Rollouts.
* **Stable ReplicaSet** is the current production version.
* **New or candidate ReplicaSet** is the version being introduced and validated.

Strategy-dependent components:

* **Active Service** is used by Blue/Green rollouts to send production traffic to the active version.
* **Preview Service** is optionally used by Blue/Green rollouts to expose the candidate version before promotion.
* **Stable Service** is used by traffic-routed Canary rollouts to identify the stable version for the traffic provider.
* **Canary Service** is used by traffic-routed Canary rollouts to identify the candidate version for the traffic provider.
* **Ingress controller or service mesh** is required when a rollout needs explicit request-level traffic weights instead of replica-based approximation.

Optional validation components:

* **`AnalysisTemplate`** defines how to measure rollout health, including metric queries, success conditions, and failure conditions.
* **`AnalysisRun`** is an execution of an `AnalysisTemplate` during a rollout.
* **`Experiment`** creates temporary ReplicaSets, often for baseline-versus-candidate comparison or controlled validation before promotion.

Related but separate component:

* **Argo CD** reconciles Kubernetes resources from Git. It may apply a `Rollout` definition and display rollout health, but Argo Rollouts controls runtime promotion, pauses, traffic movement, analysis, and abort behavior.

Metric analysis, experiments, Argo CD, and service-mesh integration are optional capabilities. Services used for Blue/Green and traffic-routed Canary strategies are part of those rollout designs.

## Deployment Strategies

### Kubernetes RollingUpdate

Kubernetes RollingUpdate gradually replaces pods. The existing Kubernetes Service distributes traffic across ready pods that match its selector. There is normally no explicit stable-versus-candidate traffic policy, no built-in metric analysis, and no separate promotion event.

This is simple and suitable for many low-risk applications.

### Blue/Green

Blue/Green keeps two application versions available at the same time. One version is active and receives production traffic. The other version is available for preview and validation.

Promotion changes which version receives production traffic. In Kubernetes this usually means changing Service selectors, not moving traffic between clusters. The old version can remain available briefly after promotion, which allows faster rollback if a problem appears immediately.

### Canary

Canary introduces a new version gradually. A small part of capacity or traffic uses the candidate version first. Exposure then increases through rollout steps.

Each step can pause for manual review, wait for a fixed duration, run analysis, start an experiment, or continue automatically. The rollout completes only when the candidate becomes the stable version.

| Area | RollingUpdate | Blue/Green | Canary |
|---|---|---|---|
| Traffic movement | Service sends traffic to ready pods | Production Service switches from one version to another | Traffic or pod share changes step by step |
| Running versions | Usually overlaps during replacement | Two complete versions during validation | Stable and candidate during rollout |
| Promotion model | Implicit | Explicit cutover | Gradual promotion |
| Rollback behavior | Return to an older revision | Switch back while old version is retained | Abort and return traffic or capacity to stable |
| Requirements | Kubernetes Deployment and Service | Additional Services and capacity | Steps; optional traffic provider and metrics |
| Best fit | Low-risk changes | Clear cutover and preview validation | Gradual exposure with useful live signals |

## Blue/Green Deployment Flow

1. The stable version serves production traffic.
2. A new ReplicaSet is created.
3. The preview Service points to the new version.
4. The active Service continues pointing to the stable version.
5. The new version is validated.
6. Promotion switches production traffic to the new version.
7. The previous version is retained temporarily.
8. The previous version is eventually scaled down.
9. If validation fails, promotion is stopped or the rollout is aborted.

```mermaid
flowchart LR
    Users[Users] --> ActiveBefore[Active Service]
    ActiveBefore --> Stable[Stable version v1]

    Validation[Testing and validation] --> Preview[Preview Service]
    Preview --> Candidate[Candidate version v2]

    Candidate --> Decision{Promote?}
    Decision -->|No| Abort[Abort rollout]
    Decision -->|Yes| ActiveAfter[Active Service after promotion]

    ActiveAfter --> Candidate
    Stable -. retained during scale-down delay .-> Rollback[Fast rollback window]
```

The **Active Service** is the production entry point. Before promotion, it selects the stable version. After promotion, it selects the candidate version.

The **Preview Service** is a separate entry point for validation. It can be used by smoke tests, internal checks, or pre-promotion analysis without sending normal production traffic to the candidate.

The **stable version** is the current production ReplicaSet. The **candidate version** is the new ReplicaSet created from the changed Pod template.

**Promotion** changes which ReplicaSet receives production traffic. In a normal Blue/Green rollout this is a Service selector change inside the cluster, not a physical movement of traffic between clusters.

The **scale-down delay** keeps the previous ReplicaSet available for a short period after promotion. That creates a **rollback window** where traffic can switch back quickly. Teams should still test rollback behavior because controller reconciliation, load balancer updates, application startup, and external dependencies can affect timing.

Promotion can be manual or automatic. Manual promotion waits for an operator decision. Automatic promotion continues after configured conditions, such as a delay or successful analysis.

## Canary Deployment Flow

1. The stable version initially receives all traffic.
2. A candidate ReplicaSet is created.
3. A small percentage of users or requests reaches the candidate.
4. The rollout pauses or evaluates metrics.
5. Candidate exposure increases gradually.
6. The process repeats until the new version receives all traffic.
7. The candidate becomes stable.
8. The previous version is scaled down.
9. Failed validation aborts the rollout.

```mermaid
flowchart LR
    Start[Stable v1: 100%] --> Step1[Stable v1: 90% / Canary v2: 10%]
    Step1 --> Validate1{Validation passes?}

    Validate1 -->|Yes| Step2[Stable v1: 75% / Canary v2: 25%]
    Validate1 -->|No| Abort[Abort and return to stable v1]

    Step2 --> Validate2{Validation passes?}
    Validate2 -->|Yes| Step3[Stable v1: 50% / Canary v2: 50%]
    Validate2 -->|No| Abort

    Step3 --> Validate3{Validation passes?}
    Validate3 -->|Yes| Complete[Canary v2 becomes stable: 100%]
    Validate3 -->|No| Abort
```

The percentages are examples. Argo Rollouts does not require those exact values.

There are two important Canary models:

* **Replica-based Canary** approximates traffic share by scaling stable and candidate pods.
* **Traffic-routed Canary** uses a supported ingress controller or service mesh to set explicit request-routing weights.

## Replica-Based Canary

In a replica-based Canary, Argo Rollouts approximates traffic percentages using the number of stable and canary pods. Kubernetes Services then distribute requests across the selected ready pods.

For example, nine stable pods and one canary pod approximate a 10% canary. That does not guarantee exactly 10% of requests reach the canary. Small replica counts make percentages coarse, and long-lived connections, uneven request rates, client behavior, and session affinity can skew distribution.

Replica-based Canary is useful when the application does not need precise traffic weights and the replica count is large enough to make the approximation meaningful.

## Traffic-Routed Canary

Traffic-routed Canary integrates Argo Rollouts with a supported ingress controller or service mesh. The routing provider receives explicit traffic-weight changes, while ReplicaSet scaling can be managed separately.

This gives more accurate request distribution than replica-based Canary. It also supports patterns that pod ratios cannot express well, such as keeping the stable ReplicaSet fully scaled while sending only a small request percentage to the candidate.

Common integration categories include:

* NGINX Ingress.
* AWS Application Load Balancer.
* Istio.
* Gateway API, Kong, Traefik, Apache APISIX, Google Cloud, Service Mesh Interface, and other supported providers.

Supported features, limitations, and behavior differ by provider. Provider-specific routing semantics should be checked before relying on exact behavior.

## Rollout Steps and Pauses

Rollout steps define how a candidate version progresses. A step can set a new traffic or replica weight, pause for a fixed duration, pause until manual promotion, run analysis, start an experiment, continue to the next exposure level, or abort when validation fails.

A **timed pause** waits for a fixed duration before continuing. An **indefinite pause** waits until an operator or automation resumes the rollout. **Manual promotion** advances a paused rollout by explicit decision. **Automatic promotion** advances when configured conditions pass. **Full promotion** completes the rollout so the candidate becomes the stable version.

Pauses are useful only when the team knows what signal should be checked during the pause. Waiting longer without meaningful validation does not make a rollout safer.

## Analysis and Automated Validation

An `AnalysisTemplate` defines a validation check. It can describe which external metric provider to query, how often to query it, and which success or failure conditions decide the result.

An `AnalysisRun` is a concrete execution of that template. A rollout can run analysis inline as a blocking step or in the background while traffic continues to shift. Failed analysis can pause or abort a rollout depending on the rollout configuration.

Useful metrics may include:

* HTTP error rate.
* Request latency.
* Availability.
* Pod restart count.
* Application-specific business metrics.
* Successful transaction rate.

General flow:

1. Deploy a candidate version.
2. Send limited traffic to it.
3. Collect metrics.
4. Compare metrics with defined thresholds.
5. Increase exposure when validation succeeds.
6. Abort when validation fails.

```mermaid
flowchart LR
    Deploy[Deploy candidate] --> LimitedTraffic[Send limited traffic]
    LimitedTraffic --> Metrics[Collect metrics]
    Metrics --> Decision{Thresholds satisfied?}

    Decision -->|Yes| Continue[Increase exposure]
    Decision -->|No| Abort[Abort rollout]

    Continue --> Metrics
```

Metric quality is critical. Weak queries, missing labels, delayed data, noisy thresholds, or metrics that do not represent user impact can promote a broken version or reject a healthy one.

## Experiments

Argo Rollouts Experiments run temporary ReplicaSets and optional analysis during rollout validation. They can run multiple versions simultaneously, compare a baseline and candidate version, execute analysis against both, and support controlled tests before promotion.

An Experiment is not the same thing as a long-running production Deployment. It is a temporary validation resource, and its ReplicaSets are normally cleaned up after the experiment completes or terminates.

## Rollback and Abort Behaviour

Pausing, aborting, promoting, and rolling back are different operations.

* **Pause** stops progression at the current point.
* **Abort** stops the current rollout attempt.
* **Promote** advances the candidate toward becoming stable.
* **Rollback** moves desired state back to a previous revision.

When a rollout is aborted, the stable version remains or again becomes the production target depending on the strategy and the rollout state. Resources may not disappear immediately because scale-down delays and controller reconciliation still apply.

Rollback behavior differs between Blue/Green and Canary. Blue/Green can switch the active Service back while the old ReplicaSet is retained. Canary can return traffic or capacity to the stable ReplicaSet, especially when traffic routing leaves stable capacity available. Teams should test rollback paths instead of assuming they are instantaneous.

## Argo Rollouts and Argo CD

Argo CD and Argo Rollouts solve different problems.

### Argo CD

Argo CD reconciles Kubernetes resources from Git. It ensures the cluster matches the declared desired state and detects configuration drift.

### Argo Rollouts

Argo Rollouts controls runtime progression between application versions. It manages stable and candidate ReplicaSets and coordinates promotion, pauses, analysis, traffic changes, experiments, and aborts.

Normal flow:

```text
Git change
    ↓
Argo CD applies the desired Rollout definition
    ↓
Argo Rollouts creates and manages the new ReplicaSet
    ↓
Traffic and validation steps progress
    ↓
The new version becomes stable or the rollout is aborted
```

Argo CD may display a Rollout as progressing or suspended while Argo Rollouts waits at a pause or analysis step. Argo CD does not itself perform Canary traffic management.

## When to Use Argo Rollouts

Argo Rollouts is useful for:

* High-impact production applications.
* Services where a failed deployment can affect many users.
* Applications with reliable operational or business metrics.
* Environments requiring approval before promotion.
* Systems using service meshes or advanced ingress routing.
* Teams already using GitOps.
* Applications where fast rollback is important.
* Releases that benefit from gradual exposure.

## When It May Be Unnecessary

A standard Deployment may be enough for:

* Internal or low-risk applications.
* Small development environments.
* Applications without useful validation metrics.
* Services where running two versions simultaneously is impossible.
* Teams without capacity to maintain additional controllers and rollout logic.
* Deployments where readiness checks and RollingUpdate already provide acceptable risk.

Argo Rollouts adds operational complexity. It should solve a real release problem, not be added only because progressive delivery sounds safer.

## Operational Considerations

Argo Rollouts adds CRDs and a controller that must be installed, upgraded, monitored, and authorized. It can create extra ReplicaSets and temporary workloads, so clusters need enough capacity to run stable and candidate versions at the same time.

Autoscaling requires care. The HPA sets the desired replica count on the Rollout scale subresource, while the Argo Rollouts controller allocates pods across ReplicaSets according to the strategy. PodDisruptionBudgets, readiness probes, liveness probes, and startup probes still matter because they affect availability and endpoint selection.

Application design must support two versions running at the same time. Backward-compatible APIs, events, queues, background workers, session handling, and long-lived connections all need review. Stateful workloads are harder because traffic movement and ReplicaSet scaling do not automatically solve data compatibility.

Database migrations are a common failure point. A new version may require a schema change while the old version is still running. Destructive migrations can break the stable version during the rollout. Expand-and-contract migrations are safer: add compatible schema first, deploy compatible application versions, then remove old fields only after no running version needs them.

Operational teams should also consider:

* Promotion permissions and RBAC.
* Metric reliability and alert quality.
* Ingress-controller-specific behavior.
* Rollback testing.
* Version pinning and controller upgrades.
* Behavior during consecutive application updates.

## Limitations and Common Misconceptions

* A healthy pod does not necessarily mean a healthy application.
* Canary percentages are not always exact without traffic routing.
* Argo Rollouts does not automatically define meaningful application metrics.
* Argo Rollouts does not replace an ingress controller or service mesh.
* Argo Rollouts does not replace Argo CD.
* Blue/Green does not automatically guarantee zero downtime.
* Rollback cannot undo incompatible database changes.
* More rollout stages do not automatically make a deployment safer.
* Progressive delivery still requires monitoring, capacity planning, and operational ownership.

## Blue/Green Versus Canary

Blue/Green is generally appropriate when a complete candidate environment must be validated before cutover, fast switching between complete versions is valuable, additional temporary capacity is acceptable, and a clear promotion event is desired.

Canary is generally appropriate when risk should be reduced through gradual user exposure, the application can be validated using live production traffic, traffic weighting or sufficient replica counts are available, and the team has reliable monitoring and automated analysis.

Neither strategy is universally better. Blue/Green gives a clear switch between complete versions. Canary gives gradual exposure and finer control, but it depends more heavily on traffic distribution and metric quality.

## Summary

Argo Rollouts adds progressive delivery controls to Kubernetes. It replaces the standard Deployment resource with a Rollout resource that can manage stable and candidate ReplicaSets through Blue/Green, Canary, pauses, analysis, experiments, and traffic routing.

Blue/Green validates a candidate version separately and then switches production traffic to it. Canary exposes the candidate gradually until it becomes stable. Replica-based Canary approximates request share through pod counts, while traffic-routed Canary uses an ingress controller or service mesh for explicit request weights.

Automated analysis can promote or stop a rollout based on metrics, but it is only as reliable as the metrics and thresholds behind it. Argo CD can apply and observe Rollout resources from Git, but Argo Rollouts performs the runtime rollout control.

The trade-off is safer and more controlled releases in exchange for additional controller, configuration, capacity, routing, monitoring, and operational complexity.

## References

* [Argo Rollouts documentation](https://argoproj.github.io/argo-rollouts/)
* [Argo Rollouts concepts](https://argoproj.github.io/argo-rollouts/concepts/)
* [BlueGreen deployment strategy](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
* [Canary deployment strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
* [Traffic management](https://argoproj.github.io/argo-rollouts/features/traffic-management/)
* [Analysis and progressive delivery](https://argoproj.github.io/argo-rollouts/features/analysis/)
* [Experiments](https://argoproj.github.io/argo-rollouts/features/experiment/)
* [Argo CD integration FAQ](https://argoproj.github.io/argo-rollouts/FAQ/)
* [Rollout specification](https://argoproj.github.io/argo-rollouts/features/specification/)
