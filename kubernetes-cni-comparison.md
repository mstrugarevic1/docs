# Kubernetes CNI Comparison

## Table of Contents

- [What is CNI?](#what-is-cni)
- [Why is CNI necessary?](#why-is-cni-necessary)
- [How networking works in Kubernetes](#how-networking-works-in-kubernetes)
- [Key networking concepts](#key-networking-concepts)
- [Why different CNIs are necessary?](#why-different-cnis-are-necessary)
- [Default CNI by platform](#default-cni-by-platform)
- [CNI comparison table](#cni-comparison-table)
- [Management: CLI and UI Tools](#management-cli-and-ui-tools)
- [Common troubleshooting commands](#common-troubleshooting-commands)
- [Practical recommendation](#practical-recommendation)

## What is CNI?

CNI (Container Network Interface) is a CNCF project that consists of a specification and libraries for writing plugins to configure network interfaces in Linux containers. Kubernetes uses CNI as an interface between the container runtime and network implementation.

- CNI stands for Container Network Interface.
- Kubernetes uses CNI plugins to provide pod networking.
- CNI allows pods to communicate with other pods, nodes, and services.

## Why is CNI necessary?

Kubernetes does not provide a built-in network implementation. Instead, it defines a networking model and relies on CNI plugins to implement it. CNI is necessary because:

- It standardizes how network interfaces are created and destroyed.
- It decouples the container runtime (CRI) from the network implementation.
- It allows for a diverse ecosystem of networking solutions (overlay, BGP, eBPF, etc.).
- It handles IP Address Management (IPAM) for pods.

## How networking works in Kubernetes

Kubernetes networking is based on a flat network structure where every pod has a unique IP address and can communicate with any other pod in the cluster without NAT.

1.  **Pod-to-Pod Communication**: Pods can reach each other using their internal IP addresses. CNI ensures that traffic is routed correctly between nodes.
2.  **Pod-to-Service Communication**: Services provide a stable IP (ClusterIP) that load balances traffic to a set of pods. This is usually handled by `kube-proxy` or a CNI replacement like Cilium.
3.  **External-to-Service Communication**: Managed via LoadBalancers, NodePorts, or Ingress controllers.
4.  **Node-to-Pod Communication**: Nodes can reach pods directly.

## Key networking concepts

| Concept | Meaning |
|---|---|
| Overlay networking | Pod traffic is encapsulated between nodes. Easier to run, but adds some overhead. |
| Native / routed networking | Pod IPs are routable directly in the underlying network. Better integration, but requires more planning. |
| IPAM | IP Address Management. Responsible for assigning IP addresses to pods. |
| NetworkPolicy | Kubernetes object used to control traffic between pods. |
| eBPF | Linux kernel technology used by modern CNIs like Cilium for faster networking, policy enforcement, and observability. |
| BGP | Routing protocol often used by CNIs like Calico for direct pod routing. |
| kube-proxy replacement | Some CNIs, like Cilium, can replace kube-proxy and handle service routing themselves. |

## Why different CNIs are necessary?

Different environments and use cases require different networking approaches:

- **Cloud Integration**: AWS, Azure, and Google Cloud have native CNIs that integrate directly with their VPC/VNet infrastructure for better performance and security.
- **Performance**: eBPF-based CNIs (like Cilium) offer lower latency and higher throughput by bypassing parts of the standard Linux networking stack.
- **Scale**: Large-scale clusters often use BGP-based CNIs (like Calico) to avoid the overhead of overlay networks.
- **Security**: Some CNIs focus heavily on fine-grained NetworkPolicies and encryption (WireGuard/IPsec).
- **Specialized Networking**: Environments like Telco or NFV may need multiple interfaces per pod, which is where Multus is used.

## Default CNI by platform

| Platform | Default CNI / Networking | Notes |
|---|---|---|
| EKS | Amazon VPC CNI | Pods get IP addresses from AWS VPC subnets. |
| AKS | Azure CNI Overlay / Azure CNI | Modern AKS clusters commonly use Azure CNI Overlay. Azure CNI powered by Cilium is also available. |
| GKE Standard | Google CNI / GKE Dataplane V2 optional | GKE Dataplane V2 is Cilium-based and can be used instead of the legacy dataplane. |
| GKE Autopilot | GKE Dataplane V2 | Cilium-based dataplane. |
| Kubespray | Calico | Calico is the usual default CNI in Kubespray. |
| OpenShift | OVN-Kubernetes | Default OpenShift networking provider. |

Note: Default networking options can change between Kubernetes versions and managed Kubernetes providers. Always verify the current default in the official provider documentation before designing a production cluster.

## CNI comparison table

| CNI | Typical usage | Pros | Cons |
|---|---|---|---|
| Flannel | Simple Kubernetes clusters, Labs, Lightweight setups | Very simple, Easy to install, Good for learning and basic networking | Limited advanced networking features, Does not provide strong NetworkPolicy support by itself, Not ideal for complex production security requirements |
| Calico | Self-managed Kubernetes, Kubespray, On-prem production clusters, Enterprise clusters | Mature and widely used, Strong NetworkPolicy support, Supports BGP, Can work with overlay and non-overlay networking | More complex than Flannel, BGP mode requires networking knowledge, Troubleshooting can be harder for beginners |
| Cilium | Modern Kubernetes clusters, eBPF-based networking, Security and observability focused environments | Uses eBPF, Strong NetworkPolicy support, Supports L3/L4/L7 policies, Includes Hubble for observability, Can replace kube-proxy | More complex to understand, eBPF debugging requires deeper Linux knowledge, More moving parts than simple CNIs |
| Canal | Older clusters using Flannel networking with Calico policy | Combines Flannel networking with Calico policy, Useful migration path from simple networking to policies | Less common today, Mostly legacy use case, Not usually chosen for new clusters |
| Weave Net | Older Kubernetes clusters, Legacy environments | Simple user experience, Historically popular, Supports basic NetworkPolicy through add-ons | Not a common choice for new production clusters, Less modern than Calico or Cilium, Smaller adoption today |
| Antrea | VMware Tanzu, Enterprise Kubernetes, Mixed Linux/Windows clusters | Based on Open vSwitch, Good enterprise networking model, Supports NetworkPolicy | Less common outside VMware/Tanzu environments, Smaller community compared to Calico and Cilium |
| Kube-router | Lightweight Kubernetes clusters, BGP-based routing setups | Provides routing, service proxy, and NetworkPolicy, Uses BGP for direct pod routing, Lightweight | Less mainstream, Smaller ecosystem, Less common in managed Kubernetes |
| Amazon VPC CNI | EKS default networking | Native AWS VPC integration, Pods get real VPC IP addresses, Works well with AWS networking, routing, and security groups | Can hit subnet IP exhaustion, ENI/IP limits must be planned carefully, AWS-specific |
| Azure CNI | AKS clusters, Azure VNet integrated networking | Native Azure VNet integration, Good for enterprise Azure environments, Predictable networking model | Can consume many VNet IP addresses, Azure-specific, Requires subnet planning |
| Azure CNI powered by Cilium | Modern AKS clusters, eBPF dataplane on Azure | Combines Azure CNI with Cilium dataplane, Better performance and scalability, Stronger policy capabilities, Modern eBPF-based approach | AKS-managed implementation, Not the same as fully self-managed Cilium, Azure-specific limitations may apply |
| Google CNI | GKE Standard clusters | Native GCP/GKE integration, Managed by Google, Works well with VPC-native GKE clusters | GCP-specific, Less flexible than self-managed Calico or Cilium |
| GKE Dataplane V2 | GKE Autopilot, Modern GKE Standard clusters | Cilium-based, eBPF dataplane, Managed by Google, Better visibility and security than legacy dataplane | GKE-managed, Less manual control than self-managed Cilium, GCP-specific |
| OVN-Kubernetes | OpenShift, Enterprise Kubernetes networking | Default OpenShift networking provider, Strong enterprise networking features, Based on OVN/Open vSwitch | Mostly used in OpenShift context, More complex than simple CNIs, Not usually selected manually for vanilla Kubernetes |
| Multus | Telco, NFV, Edge, Pods requiring multiple network interfaces | Allows multiple network interfaces per pod, Useful for advanced networking, Works as a meta-plugin with other CNIs | Not a normal default CNI, More complex operational model, Usually needed only for special cases |

## Management: CLI and UI Tools

Many CNI plugins provide dedicated tools for management, troubleshooting, and observability.

| CNI | CLI Tool | UI / Observability |
|---|---|---|
| Cilium | `cilium` CLI | Hubble (UI and CLI) |
| Calico | `calicoctl` | Calico Cloud/Enterprise UI |
| Antrea | `antrectl` | Antrea UI (Grafana dashboards) |
| Amazon VPC CNI | `aws` CLI (for ENI/IP management) | AWS VPC flow logs |
| Azure CNI | `az` CLI | Azure Monitor |
| GKE Dataplane V2 | `gcloud` CLI | Cloud Logging / Monitoring |

## Common troubleshooting commands

```bash
kubectl get pods -n kube-system
kubectl get daemonset -n kube-system
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl describe node <node-name>
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

### CNI-specific examples

```bash
# Cilium
cilium status
cilium connectivity test
hubble observe

# Calico
calicoctl node status
calicoctl get ippool -o wide

# EKS / Amazon VPC CNI
kubectl get daemonset aws-node -n kube-system
kubectl logs -n kube-system daemonset/aws-node

# AKS
kubectl get pods -n kube-system
az aks show --resource-group <resource-group> --name <cluster-name> --query networkProfile

# GKE
kubectl get pods -n kube-system
gcloud container clusters describe <cluster-name> --region <region>
```

## Practical recommendation

| Scenario | Recommended CNI |
|---|---|
| Simple lab cluster | Flannel |
| Kubespray / self-managed production | Calico |
| Modern eBPF-based networking | Cilium |
| EKS production | Amazon VPC CNI |
| AKS production | Azure CNI Overlay or Azure CNI powered by Cilium |
| GKE production | GKE Dataplane V2 |
| OpenShift | OVN-Kubernetes |
| Telco / NFV / multi-interface pods | Multus |
