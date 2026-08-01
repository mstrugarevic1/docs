# Common Amazon EKS Production Problems

AWS manages the Amazon EKS control plane, but many production failures happen in customer-managed or customer-configured components: worker nodes, networking, add-ons, IAM, storage, workloads, ingress controllers, and external AWS services that the cluster depends on.

## Table of Contents

- [Common EKS Failure Patterns from Official Guidance](#common-eks-failure-patterns-from-official-guidance)
- [Production Incidents from Public Engineering Reports](#production-incidents-from-public-engineering-reports)
- [Recurring Failure Themes](#recurring-failure-themes)
- [References](#references)

## Common EKS Failure Patterns from Official Guidance

The following table summarizes recurring EKS failure patterns described across AWS and Kubernetes guidance. It is intended as a recognition catalog rather than a troubleshooting guide: each row identifies a problem that engineers may encounter and the production symptoms it can produce.

| Area | Common problem | What it may look like |
|---|---|---|
| Control plane | Kubernetes API latency or throttling can be caused by excessive controller, agent, or bootstrap requests. | Controllers slow down, nodes fail to join, or API clients receive throttling errors while existing Pods may keep running. |
| Admission control | Admission webhooks can block API writes when they are unavailable, too broad, or configured to fail closed. | Deployments, updates, node changes, or system component writes hang or fail even though the API Server is reachable. |
| Node bootstrap | Worker nodes can fail to join because of IAM, AMI, bootstrap, DNS, STS, route, subnet, or security group problems. | EC2 instances launch, but the cluster never gets usable Kubernetes nodes. |
| EC2 capacity | The requested instance type or Availability Zone may not have enough capacity. | Managed node group upgrades, scale-outs, or Karpenter replacements cannot create the expected nodes. |
| Karpenter | Karpenter can fail to launch or register replacement nodes because of launch template, IAM, CNI, or node initialization problems. | Pods remain unscheduled while replacement capacity exists only as failed or uninitialized EC2 attempts. |
| Managed node groups | Managed node group resources or IAM instance profiles can be missing or unhealthy. | EKS reports node group health issues such as missing roles, missing instance profiles, failed launches, or failed node registration. |
| Subnet capacity | Subnets can run out of addresses for nodes, Pods, or EKS-managed interfaces. | Pods fail to get IPs, nodes fail to launch, or cluster operations report insufficient free addresses. |
| Pod density | ENI and per-instance Pod-density limits cap how many Pods a node can support. | Nodes have CPU and memory left but cannot accept more Pods that need VPC IPs. |
| Prefix delegation | Prefix assignment can fail when the subnet lacks a contiguous `/28` IPv4 block. | Prefix mode is enabled, but new Pod address capacity is not available even when scattered free IPs remain. |
| VPC CNI warm pools | VPC CNI warm ENI, IP, or prefix pools can reserve more subnet addresses than expected. | Subnets appear full before the number of running Pods explains the usage. |
| Conntrack | Conntrack-table exhaustion or stale conntrack entries can break network flows or DNS traffic. | Services see intermittent timeouts, stale routing, or dropped connections from otherwise healthy Pods. |
| CoreDNS | CoreDNS can be saturated, under-replicated, disrupted during scale-down, or affected by upstream DNS failures. | Applications report DNS timeouts, dependency connection failures, or intermittent service discovery errors. |
| Node resources | Nodes can exhaust file descriptors, PIDs, disk, inodes, memory, or ephemeral storage. | Pods are evicted, nodes become `NotReady`, or containers fail despite application code being unchanged. |
| Node upgrades | Managed node group upgrades can fail with `PodEvictionFailure`. | Old nodes remain in service because EKS cannot drain Pods during the upgrade window. |
| Disruption policy | Pod Disruption Budgets can prevent voluntary node draining. | Upgrades, consolidation, or scale-down operations stall because eviction would violate availability policy. |
| Kubernetes upgrades | Deprecated Kubernetes APIs can break workloads or controllers after a version upgrade. | Objects stop applying, controllers fail to reconcile, or an upgrade insight flags API usage that must move to a supported version. |
| Add-ons | CoreDNS, VPC CNI, kube-proxy, CSI, or load balancer controller versions can be incompatible with the cluster or workload assumptions. | System Pods are running, but networking, DNS, storage, or ingress behavior changes after an add-on or cluster upgrade. |
| IAM and identity | IRSA, EKS Pod Identity, OIDC, STS, or IAM trust-policy failures can prevent Pods or controllers from using AWS APIs. | Applications start but cannot access AWS services, or controllers cannot create cloud resources. |
| Load balancing | ALB or NLB provisioning can fail because of IAM, annotations, target type, subnet discovery, or subnet IP constraints. | Ingress or Service objects exist, but the expected load balancer, listener, target group, or healthy targets do not appear. |
| Image pulls | ECR authentication, permissions, endpoint, repository, or image tag problems can block image pulls. | Pods stay in image pull backoff states and deployments never reach the desired replica count. |
| Storage | EBS volumes are bound to one Availability Zone. | A StatefulSet or rescheduled Pod cannot attach its volume after being placed in a different zone. |
| Regional dependencies | Regional AWS degradation can leave existing Pods running while new nodes, load balancers, images, or deployments cannot be created. | The application partially serves traffic, but scaling, rollout, recovery, or provisioning paths fail. |

## Production Incidents from Public Engineering Reports

Official documentation describes expected failure modes, while public engineering reports show how similar problems appeared in real systems. These cases are intentionally summarized to the reported failure and one reusable lesson rather than presenting complete incident timelines or root-cause analyses.

| Company or report | Reported problem | Short lesson |
|---|---|---|
| Stytch | Managed node group cleanup removed an IAM instance profile that Karpenter depended on, so replacement nodes could not launch and services lost capacity. | EKS-managed resources and self-managed autoscaling must not share hidden IAM or instance-profile assumptions. |
| Adevinta | An EKS migration exposed subnet and Pod IP exhaustion risk from Amazon VPC CNI address allocation. | VPC IP space is production capacity, not just network plumbing. |
| Neon | AWS VPC CNI address allocation and warm pools contributed to subnet IP exhaustion during a production outage. | Allocated IPs can become the limiting factor before running Pods consume the expected number of addresses. |
| Freshworks | CoreDNS Pods on a failed node and stale conntrack mappings caused intermittent DNS resolution failures in an EKS cluster. | DNS availability depends on CoreDNS placement, node health, kube-proxy behavior, and Linux conntrack state. |
| Preply - General Kubernetes issue relevant to EKS | CoreDNS autoscaling and stale conntrack state caused a partial Kubernetes DNS outage. | DNS failures can be partial and service-specific when stale network state survives endpoint changes. |
| EKS migration missing-packet report | During a migration to EKS, traffic from Pods to services outside the cluster failed intermittently because of AWS VPC CNI SNAT behavior. | EKS networking changes source-address behavior; external dependencies may observe different traffic than before migration. |
| MIT xPRO - General Kubernetes issue relevant to EKS | Certificate renewal failed because Fastly and cert-manager both attempted to manage ACME DNS validation for related domains. | DNS and certificate ownership boundaries matter as much as the Kubernetes certificate object. |
| Honeycomb | A Kafka migration to EKS carried operational and customer-impact risk because stateful systems need careful rollback, telemetry, and migration choreography. | Stateful workloads on EKS fail differently from stateless services; capacity, data movement, and customer communication are part of the risk. |

## Recurring Failure Themes

Across official guidance and public incident reports, the same themes recur: limited capacity, IP allocation, DNS and conntrack behavior, node resource exhaustion, IAM dependencies, add-on compatibility, upgrades, load balancing, Availability Zone constraints, regional AWS dependencies, and the operational complexity of stateful workloads.

## References

### Official Documentation

- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Amazon EKS Best Practices Guide](https://docs.aws.amazon.com/eks/latest/best-practices/introduction.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

### Engineering Reports and Postmortems

- [Stytch postmortem: managed node group cleanup and Karpenter instance profile failure](https://stytch.com/blog/stytch-postmortem-2023-02-23/)
- [Adevinta: avoiding an outage caused by running out of IPs in EKS](https://adevinta.com/techblog/how-we-avoided-an-outage-caused-by-running-out-of-ips-in-eks/)
- [Neon: AWS CNI lessons from a production outage](https://neon.com/blog/aws-cni-lessons-from-a-production-outage)
- [Freshworks: decoding CoreDNS failures](https://medium.com/freshworks-engineering-blog/decoding-coredns-failures-75ebdc89ac0b)
- [Preply: DNS postmortem](https://medium.com/preply-engineering/dns-postmortem-e169efd45afd)
- [The case of the missing packet: an EKS migration tale](https://yashmehrotra.com/posts/the-case-of-the-missing-packet-an-eks-migration-tale/)
- [MIT xPRO outage: ACME DNS ownership conflict](https://engineering.ol.mit.edu/runbooks_post_mortems/20260603_xpro_outage/)
- [Honeycomb: transforming how they run Kafka at Honeycomb](https://www.honeycomb.io/blog/transforming-how-we-run-kafka-honeycomb)
