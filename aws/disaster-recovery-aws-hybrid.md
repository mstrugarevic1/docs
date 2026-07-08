# AWS and Hybrid Disaster Recovery Guide

This guide explains practical disaster recovery concepts for AWS-hosted workloads and hybrid on-premises/AWS environments. It is written for Senior DevOps, Platform, SRE, and Cloud Engineers who need to discuss recovery architecture in design reviews, production readiness reviews, or interviews.

The examples are intentionally simplified. Actual recovery targets and implementation details must be based on business requirements, application behavior, data consistency needs, and tested operational procedures.

## 1. Disaster Recovery Overview

Disaster recovery (DR) is the ability to restore a workload after a major event makes the primary environment unavailable or unusable. A disaster can be a Regional outage, data corruption, ransomware event, failed migration, major network failure, or loss of an on-premises site.

DR is part of business continuity. Business continuity covers how the organization continues operating during disruption: people, processes, communication, customer support, legal obligations, and technical recovery. DR is the technical and operational recovery of systems and data that support those business processes.

These terms are related but not interchangeable:

| Term | Practical meaning |
| :--- | :--- |
| **High availability** | Keeps a service running through expected component failures such as instance, node, disk, or Availability Zone issues. |
| **Backup** | Creates recoverable copies of data or configuration. Backups are an input to recovery, not the complete recovery process. |
| **Disaster recovery** | Restores service after a major event that makes the primary environment unavailable. |
| **Business continuity** | Keeps the business operating before, during, and after disruption, including non-technical processes. |

High availability handles expected component failures. Disaster recovery handles a major event that makes the primary environment unavailable. Having backups does not automatically mean that a usable DR solution exists. A real DR solution also needs infrastructure, access, network routing, runbooks, validation, and tested failback.

## 2. Recovery Time Objective and Recovery Point Objective

### Recovery Time Objective - RTO

Recovery Time Objective (RTO) is the maximum acceptable amount of time between a service interruption and service restoration.

RTO answers:

> How long can the service remain unavailable?

### Recovery Point Objective - RPO

Recovery Point Objective (RPO) is the maximum acceptable amount of data loss measured in time.

RPO answers:

> How much recent data can the business afford to lose?

Simple example:

* Backup or replication point: `10:00`
* Disaster: `10:15`
* Service restoration: `11:00`
* RPO: 15 minutes
* RTO: 45 minutes

Lower RTO and RPO values normally require more automation, more infrastructure, continuous replication, more testing, greater operational maturity, and higher cost. A workload with a 15-minute RTO needs a different operating model than a workload that can wait until the next business day.

![Disaster recovery RTO and RPO overview](images/disaster-recovery.png)

## 3. Defining Recovery Objectives

RTO and RPO should be defined per workload, not once for the entire company. A payment API, internal reporting job, and development wiki rarely need the same recovery targets.

Inputs for recovery objectives include:

* Business impact analysis
* Financial impact
* Contractual SLAs
* Compliance requirements
* Customer impact
* Operational dependencies
* Acceptable cost
* Application criticality

Example workload tiers:

| Workload tier | Example workload                             |   Example RTO |             Example RPO |
| ------------- | -------------------------------------------- | ------------: | ----------------------: |
| Tier 1        | Payment or customer-facing critical service  | 15-60 minutes | Near zero to 15 minutes |
| Tier 2        | Important internal or supporting service     |     2-4 hours |               1-2 hours |
| Tier 3        | Non-critical reporting or development system |    8-24 hours |              4-24 hours |

These are examples, not universal standards. The correct values come from business ownership and tested technical feasibility.

## 4. AWS Disaster Recovery Strategies

AWS DR strategies are commonly discussed as backup and restore, pilot light, warm standby, and multi-site active/active. The right strategy depends on workload criticality, acceptable data loss, recovery time, operational maturity, and cost.

| Strategy | Infrastructure state | Typical recovery characteristics | Cost | Complexity | Appropriate use cases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Backup and restore** | Data and configuration are backed up; infrastructure is recreated during recovery. | Longest RTO and RPO; depends on restore speed and automation quality. | Lowest | Low to medium | Non-critical systems, lower-cost DR, workloads that tolerate hours of downtime. |
| **Pilot light** | Critical data and core components are replicated; most compute is stopped or absent. | Faster than backup and restore; compute is launched or scaled during recovery. | Low to medium | Medium | Important workloads where data must be ready but full capacity is not always running. |
| **Warm standby** | Complete reduced-capacity environment is already running. | Faster recovery; scale up during failover. | Medium to high | Medium to high | Business-critical systems with tighter RTO than pilot light. |
| **Multi-site active/active** | Multiple locations actively serve production traffic. | Lowest potential RTO and RPO, but consistency and operations are difficult. | Highest | Highest | Critical workloads that justify continuous multi-location operation. |

### Backup and Restore

Backup and restore means data and configuration are backed up, and infrastructure is recreated after a disaster. Infrastructure as Code should be used so recovery does not depend on engineers manually rebuilding networks, compute, IAM, and application configuration.

Typical AWS building blocks include AWS Backup, Amazon S3, EBS snapshots, RDS snapshots, DynamoDB point-in-time recovery, Terraform, and CloudFormation. This is normally the least expensive option, but it usually has the longest RTO and RPO.

### Pilot Light

Pilot light keeps critical data and core components continuously replicated while most application compute is stopped or not provisioned. During recovery, compute is started, scaled, or created from templates. AWS Elastic Disaster Recovery commonly follows this general model by replicating source servers into a low-cost staging area and launching recovery instances when needed.

### Warm Standby

Warm standby keeps a complete but reduced-capacity environment already running. Data is continuously replicated, and the environment is scaled up during failover. This improves recovery time compared with pilot light, but it costs more because more infrastructure is always active.

### Multi-Site Active/Active

Multi-site active/active means multiple locations actively serve production traffic. Traffic must be routed away from the failed location, and the application must tolerate or resolve distributed data consistency issues. This strategy offers the lowest potential RTO and RPO, but it has the highest operational complexity and cost. Active/active does not automatically provide zero data loss.

## 5. Multi-AZ Is Not the Same as Multi-Region DR

Multi-AZ architecture spreads resources across Availability Zones inside an AWS Region. It provides strong protection against many infrastructure failures, including instance failure and some Availability Zone-level events.

Multi-Region DR means the workload can recover into another AWS Region. This requires separate planning for data replication, infrastructure, identity, secrets, network routing, service quotas, observability, and operating procedures.

A Multi-AZ architecture does not necessarily satisfy a requirement for recovery from a complete Regional outage. The correct design depends on the workload's explicitly defined disaster scenarios.

## 6. AWS Disaster Recovery Building Blocks

### Infrastructure

DR infrastructure should be reproducible and version-controlled. Terraform or CloudFormation can define VPCs, subnets, routing, security groups, IAM, load balancers, compute, databases, alarms, and supporting services. Reusable modules reduce drift, but they should still be understandable during an incident.

Recovery accounts and VPCs may need to exist before a disaster. Service quotas must be checked in the recovery Region. AMIs, container images, configuration, and dependency management must also be recoverable. A perfect database restore is not useful if the application image or required configuration is unavailable.

### Data

Data recovery uses database replication, cross-Region read replicas where supported, snapshots, point-in-time recovery, S3 versioning and cross-Region replication, EBS snapshots, DynamoDB global tables where appropriate, and application-level consistency controls.

Database recovery must account for consistency between related systems, not only individual backups. For example, restoring an order database to one point in time and a payment ledger to another can create business-level inconsistency even if both restores succeed technically.

### Networking and Traffic Management

Traffic management commonly uses Route 53, health checks, DNS failover, load balancers, AWS Transit Gateway, VPN, Direct Connect, and planned DNS TTL values. DNS failover is not instantaneous because clients and recursive resolvers can cache records. Low TTLs help, but they do not guarantee every client switches at the same time.

### Identity and Security

Recovery requires IAM roles and policies, KMS keys, Secrets Manager or Parameter Store values, certificates, replicated or recoverable secrets, break-glass access, and least privilege. The recovery Region must not depend on security resources that are available only in the failed environment.

KMS key strategy matters. Some services support multi-Region keys, while others need explicit key and policy planning. Secrets and certificates should be tested during recovery, not assumed to work.

### Observability

Recovery readiness depends on CloudWatch metrics and logs, centralized logging, synthetic checks, replication lag monitoring, backup failure alerts, recovery readiness dashboards, and post-failover application validation. Monitoring should tell the team whether replication is healthy before the disaster, not only after recovery fails.

## 7. Hybrid Disaster Recovery: On-Premises to AWS

A common hybrid DR model runs production on-premises and uses AWS as the recovery location. This can reduce the need for a second physical data center, but it still requires tested networking, replication, security, and failback.

### Connectivity

Primary connectivity often uses AWS Direct Connect where bandwidth, latency, cost, or consistency justify it. Backup connectivity should use Site-to-Site VPN or another independent path. Relying on a single network path creates another single point of failure.

Connectivity design should account for routing, firewall rules, DNS, MTU, bandwidth, monitoring, and who can change network controls during an incident.

### Server Replication

AWS Elastic Disaster Recovery can continuously replicate supported source servers into a low-cost staging area in AWS and launch recovery instances during a drill or disaster. It uses a source replication agent, staging subnet, replication servers, point-in-time recovery, drill instances, recovery instances, and planned failback procedures.

AWS Elastic Disaster Recovery is not the only possible solution. Some environments use application-level rebuilds, VM conversion tools, storage replication, database-native replication, or backup and restore.

### File and Object Data

File and object recovery may use AWS DataSync, AWS Storage Gateway, Amazon S3, AWS Backup, or native storage replication. The selected tool depends on data volume, change rate, required RPO, network bandwidth, application consistency, and restore method.

Large file sets need special attention. Initial synchronization, continuous change rate, metadata preservation, permissions, and cutover validation can dominate the recovery timeline.

### Databases

Database recovery may use database-native replication, backup and restore, AWS Database Migration Service where appropriate, or storage-level approaches. There is no universal database replication method.

The design must address transaction consistency, replication lag, promotion procedures, application connection-string changes, credentials, and rollback. A database that starts successfully but contains inconsistent or stale data may still fail the business recovery objective.

## 8. Example Hybrid Recovery Scenario

### Primary environment

```text
Users
  |
On-Premises Load Balancer
  |
Application Servers
  |
Database and File Storage
```

### Recovery environment in AWS

```text
Route 53
  |
Application Load Balancer
  |
Recovery EC2 Instances
  |
Recovered or Replicated Database
```

### Normal state

1. The application runs on-premises.
2. Servers or data are continuously replicated to AWS.
3. Infrastructure definitions and configuration are stored in version control.
4. The AWS recovery environment uses minimal running capacity.
5. Monitoring verifies replication health.

### Failover process

1. Declare the disaster.
2. Stop or isolate the primary environment where possible.
3. Select the appropriate recovery point.
4. Launch or scale the AWS recovery environment.
5. Restore or promote the database.
6. Validate secrets, certificates, and dependencies.
7. Run technical and business validation.
8. Update traffic routing.
9. Monitor the recovered service.
10. Communicate recovery status.

### Failback process

1. Repair or rebuild the primary environment.
2. Establish reverse replication.
3. Validate data consistency.
4. Schedule a controlled cutback.
5. Stop writes or use an agreed synchronization procedure.
6. Switch traffic back.
7. Confirm service health.
8. Document the incident and recovery results.

## 9. Disaster Recovery Runbook

Every workload with a DR requirement should have a runbook. Each step should have an owner, a command or action, expected output, validation criteria, escalation path, and estimated duration.

```markdown
## Disaster Recovery Runbook

### Scope

### Disaster Declaration Criteria

### Roles and Responsibilities

### Dependencies

### Recovery Prerequisites

### Failover Procedure

### Data Validation

### Application Validation

### Traffic Switch

### Communication Plan

### Failback Procedure

### Rollback and Abort Conditions

### Evidence and Audit Records
```

## 10. Testing Disaster Recovery

A DR design is not proven until it has been tested. Successful infrastructure startup is not sufficient. The service must be technically healthy and usable for its intended business function.

Useful tests include:

* Backup restore testing
* Isolated recovery drills
* Partial failover tests
* Full failover tests
* Failback tests
* Dependency validation
* Security and access validation
* DNS and routing validation
* Capacity testing
* Application and business validation

Measure actual RTO and RPO during each drill.

### Actual RTO

```text
Time service was confirmed usable
-
Time the incident or drill started
```

### Actual RPO

```text
Time of the latest successfully recovered transaction
compared with
Time the primary service stopped accepting valid writes
```

Record the evidence. The useful output of a DR test is not only pass or fail; it is the measured recovery time, measured data loss, failed assumptions, manual steps, missing permissions, and follow-up actions.

## 11. Common Disaster Recovery Mistakes

* Treating backups as a complete DR solution.
* Defining one RTO and RPO for every system.
* Never testing restores.
* Failing to test failback.
* Depending on the failed Region for IAM, secrets, or DNS operations.
* Ignoring external dependencies.
* Allowing Infrastructure as Code to drift.
* Having insufficient network bandwidth for replication.
* Missing service quotas in the recovery Region.
* Leaving manual steps undocumented.
* Having unclear authority to declare a disaster.
* Assuming Multi-AZ automatically means cross-Region DR.
* Using active/active without solving data consistency.

## 12. Practical DR Checklist

- [ ] Workload owner identified.
- [ ] Disaster scenarios defined.
- [ ] RTO approved.
- [ ] RPO approved.
- [ ] Dependencies documented.
- [ ] Replication monitored.
- [ ] Backups encrypted.
- [ ] Restore tested.
- [ ] Infrastructure reproducible.
- [ ] Recovery access verified.
- [ ] Quotas validated.
- [ ] DNS procedure tested.
- [ ] Application validation documented.
- [ ] Failback tested.
- [ ] Last drill date recorded.

## 13. Key Takeaways

* RTO determines acceptable downtime.
* RPO determines acceptable data loss.
* DR strategy is selected according to business requirements.
* Lower objectives require greater cost and complexity.
* Hybrid DR requires tested networking, replication, and failback.
* Untested disaster recovery is only an assumption.

## 14. References

* [AWS Well-Architected Framework - Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
* [Disaster Recovery of Workloads on AWS: Recovery in the Cloud](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html)
* [Disaster Recovery of On-Premises Applications to AWS](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-of-on-premises-applications-to-aws/)
* [AWS Elastic Disaster Recovery documentation](https://docs.aws.amazon.com/drs/latest/userguide/what-is-drs.html)
* [AWS Backup documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
* [AWS DataSync documentation](https://docs.aws.amazon.com/datasync/latest/userguide/what-is-datasync.html)
* [AWS Storage Gateway documentation](https://docs.aws.amazon.com/storagegateway/latest/userguide/WhatIsStorageGateway.html)
