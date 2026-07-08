# Cloud Migration Risk Register

This document tracks and manages risks associated with cloud or platform migration projects.

## How to use this Register

1.  **Identify:** List any event that could negatively impact the project.
2.  **Assess:** Rate the Impact and Probability.
3.  **Mitigate:** Define clear actions to reduce the risk.
4.  **Track:** Update the status regularly during standups.

## Impact & Probability Definitions

### Impact Levels
*   **High:** Critical path blocked; production outage.
*   **Medium:** Significant delay; high work-around effort.
*   **Low:** Minimal delay; minor impact.

### Probability Levels
*   **High:** Likely to occur.
*   **Medium:** Possible.
*   **Low:** Unlikely.

### Status Values
*   **Open:** Risk identified, no mitigation yet.
*   **Mitigating:** Mitigation plan in progress.
*   **Accepted:** Risk acknowledged, no further action planned.
*   **Closed:** Risk no longer applicable or successfully mitigated.

---

## Risk Register

| Risk Category | Risk Description | Impact | Probability | Owner | Mitigation | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Networking** | Connectivity loss between legacy and cloud | High | Medium | Networking Team | Validate VPN/DirectConnect throughput | Open |
| **DNS** | DNS propagation delay during cutover | High | Low | Platform Team | Lower TTLs 48h before cutover | Mitigating |
| **IAM** | Missing permissions for migrated services | Medium | High | Cloud Engineer | Use IaC to pre-provision roles | Open |
| **Data** | Database sync lag or data corruption | High | Medium | DBA Team | Perform mock data migrations | Open |
| **Observability** | Incomplete logging in new environment | Medium | Medium | SRE Team | Validate logs before traffic switch | Open |
| **Ownership** | Unclear support model post-migration | Medium | High | Project Manager | Assign explicit owners in kickoff | Open |
| **Cutover** | Rollback plan is untested | High | Medium | Tech Lead | Define and test rollback steps | Open |

> [!IMPORTANT]
> A risk register is only useful if it is updated. Review these risks at the start of every phase.
