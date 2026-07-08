# Incident Response Runbook

## Introduction

This document provides a practical guide for handling production incidents. It is designed to be a reliable reference for engineers during high-pressure situations, helping to reduce confusion and coordinate a successful response.

### Purpose
The purpose of this runbook is to define a clear, repeatable process for responding to production alerts, mitigating user impact, and learning from failures. It bridges the gap between receiving a page and restoring system stability.

### Audience
*   **Junior Engineers:** Learning the fundamentals of production support and on-call.
*   **Medior Engineers:** Joining an on-call rotation and taking responsibility for service reliability.
*   **DevOps / SRE / Platform Engineers:** Maintaining the infrastructure and deployment systems that power production.
*   **Application Engineers:** Supporting the services they build and deploy.

### Practice Overview
In real engineering teams, incident response is the lifecycle of an alert. It starts with an automated **page**, followed by an **acknowledgement**, initial **mitigation**, and eventually a **postmortem** to ensure the problem doesn't happen again.

---

## What Is On-Call?

On-call is a responsibility model where one or more engineers are assigned to respond to production alerts during a defined time window.

For DevOps, SRE, and Platform engineers, on-call usually exists because they maintain the foundational layers—Kubernetes clusters, cloud services, networking, and deployment pipelines—that must be reliable 24/7.

The on-call engineer is not expected to fix every issue alone. The primary responsibility is to act as the "first responder."

**The expected responsibility is to:**
*   **Acknowledge** the alert quickly to stop the escalation.
*   **Check** the affected service and environment.
*   **Understand** the impact (is it a single user or a whole region?).
*   **Start** initial mitigation (e.g., rollback, restart, scale).
*   **Escalate** when the problem requires more hands or specialized knowledge.
*   **Coordinate** communication between stakeholders.
*   **Involve** service owners or subject matter experts when required.

> [!WARNING]
> On-call without clear escalation rules is risky. A single engineer should not be the only person responsible for a major production outage.

---

## Paging and Acknowledgement

A **page** is an urgent notification sent to the current on-call engineer. Unlike a standard Slack notification, a page is designed to be disruptive to ensure it is noticed immediately.

**A page usually contains:**
*   **Affected Service:** The name of the system reporting an issue.
*   **Alert Name:** A short description of the trigger (e.g., `High 5xx Error Rate`).
*   **Severity/Priority:** Initial assessment of the problem's importance.
*   **Environment:** Production, Staging, etc.
*   **Links:** Direct access to relevant dashboards or runbooks.

### Acknowledgement and Escalation
*   **Acknowledge:** When you "Ack" a page, you signal to the system that a human is now investigating. This stops the alert from paging the next person.
*   **Escalation Timeout:** This defines how long the system waits (e.g., 5 or 10 minutes) before notifying the **Secondary On-Call** or a manager if the Primary does not respond.

---

## Severity Levels

Alerts often include an initial severity, but the on-call engineer must confirm whether it matches the real-world impact.

> [!NOTE]
> The on-call engineer should always validate whether the automated severity matches the actual user, business, or service impact.

| Severity | Meaning | Typical Handling |
| :--- | :--- | :--- |
| **SEV1** | Critical outage | Core service down; major customer impact. Immediate investigation, escalation, and incident channel. |
| **SEV2** | Serious degradation | Important feature unavailable or high latency. Investigate immediately; escalate if progress is slow. |
| **SEV3** | Non-critical issue | Partial impact with a workaround. Handled during working hours or soon after discovery. |
| **SEV4** | Low impact | Cosmetic issue or minor internal tool problem. Handled via the normal backlog or support process. |

> [!WARNING]
> Severity escalation paths are company-specific. Some organizations notify executives for SEV1s, while others keep communication strictly within engineering and support.

---

## Practical Incident Roles

In smaller teams, roles are often informal. The Primary On-Call usually acts as the first responder and initial coordinator. As incidents grow in complexity, more people are paged in.

| Role | Practical Meaning |
| :--- | :--- |
| **Primary On-Call** | The first responder who acknowledges the page and starts the investigation. |
| **Secondary On-Call** | The backup engineer who joins if the Primary is paged but unavailable. |
| **Service Owner** | The developer or team responsible for the specific application code. |
| **Platform / SRE** | Assists with infrastructure, Kubernetes, cloud resources, or networking. |
| **Engineering Manager** | Handles staffing, stakeholder coordination, and high-level escalation. |
| **Incident Coordinator** | An optional role (sometimes called **Incident Commander**) used in larger incidents to manage the process so others can focus on the fix. |

---

## Initial Response Checklist

When you receive a page, follow these steps to organize your response:

- [ ] **Acknowledge** the page immediately.
- [ ] **Check** the affected service and environment.
- [ ] **Confirm** whether the alert is real or a false positive.
- [ ] **Validate** the actual user or business impact (how many users are affected?).
- [ ] **Review** dashboards, logs, metrics, and recent deployment history.
- [ ] **Mitigate** if the cause is obvious (e.g., rollback a recent change).
- [ ] **Escalate** if you need more help or specialized knowledge.
- [ ] **Open** an incident channel or start a call for SEV1/SEV2 incidents.
- [ ] **Communicate** the current status to involved teams.

---

## When to Start an Incident Call

A call or incident bridge is usually needed when:
*   There is a **SEV1** or major **SEV2** impact.
*   Multiple teams need to coordinate a fix.
*   A critical decision like a **failover** or **regional rollback** is needed.
*   The technical investigation is blocked and needs a "war room" environment.
*   Asynchronous communication (Slack/Teams) is too slow for the required pace of response.

---

## Internal Status Updates

Internal status updates are used during SEV1 or SEV2 incidents to keep stakeholders informed without them having to ask for updates. They are not required for every minor alert.

### Status Update Template
```markdown
**Status:** [Investigating / Mitigating / Monitoring / Resolved]
**Severity:** [SEV1 / SEV2 / SEV3 / SEV4]
**Service:** Affected service name
**Impact:** Brief description of affected users or systems
**Current Action:** What the team is doing right now
**Owner:** Current responder or coordinator
**Next Update:** Expected time of the next update (e.g., in 30 mins)
```

---

## RCA and Postmortem

*   **RCA (Root Cause Analysis):** A technical deep-dive into **why** the incident happened. It focuses on the specific failure (e.g., a database connection leak).
*   **Postmortem:** A broader written review of the incident. It includes the timeline, impact, response quality, RCA, and—most importantly—**action items** to prevent recurrence.

> [!IMPORTANT]
> A good postmortem is **blameless**. The goal is to improve the system and the process, not to point fingers at an individual.

---

## Incident Management Tools

| Tool | Typical Use |
| :--- | :--- |
| **PagerDuty / Opsgenie** | On-call schedules, escalation policies, and mobile paging. |
| **Rootly / Blameless** | Incident workflows and Slack-based management. |
| **Grafana OnCall** | On-call management integrated with Grafana alerting. |
| **Alertmanager** | Grouping and routing alerts from Prometheus. |
| **Slack / MS Teams** | Real-time communication and incident channels. |
| **Jira / ServiceNow** | Tickets, post-incident tasks, and enterprise workflows. |

> [!NOTE]
> The tool is less important than the process. A good on-call process needs clear ownership, useful alerts, automated escalation, and updated runbooks.
