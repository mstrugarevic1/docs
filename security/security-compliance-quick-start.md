# SOC 2 and ISO/IEC 27001 — Practical Roadmap

> A short practical overview for CTOs, DevOps, Platform and engineering teams preparing for security audits.

This is not a complete implementation guide or legal advice. Timelines are planning estimates and depend on company size, existing security maturity, audit scope and auditor availability.

---

## 1. What are SOC 2 and ISO 27001?

| Framework                   | What it is                                                                                                                        | Main use                                                                                                                     |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **SOC 2**                   | An independent auditor's report describing whether company controls are properly designed and, for Type II, operating effectively | Commonly requested by US customers, SaaS companies, enterprise procurement and vendor-security teams                         |
| **ISO/IEC 27001**           | An international standard for establishing and operating an Information Security Management System, or ISMS                       | Commonly requested by international and enterprise customers and organizations that want a formal security-management system |
| **SOC 2 Type I**            | Evaluates control design at a specific point in time                                                                              | Useful as an initial milestone                                                                                               |
| **SOC 2 Type II**           | Evaluates control design and operation over an observation period                                                                 | Usually more valuable to enterprise customers                                                                                |
| **ISO 27001 certification** | External certification that the organization's ISMS meets ISO/IEC 27001 requirements                                              | Produces a certificate, subject to continued surveillance and recertification                                                |

SOC 2 is not technically a certification. The result is a restricted-use audit report.

ISO does not certify companies directly. Certification is performed by an external certification body.

---

## 2. What are they used for?

Companies normally pursue SOC 2 or ISO 27001 to:

* Satisfy enterprise customer requirements
* Pass vendor-security reviews
* Reduce repeated customer questionnaires
* Support sales into regulated or security-sensitive markets
* Demonstrate that security controls are documented and repeatable
* Improve access management, change management and incident response
* Create clear ownership and evidence for security activities

These frameworks do not prove that a company is impossible to breach. They demonstrate that security risks and controls are managed through defined processes.

---

## 3. Which one should the company choose?

| Company situation                                            | Typical choice                  |
| ------------------------------------------------------------ | ------------------------------- |
| US-focused SaaS selling to enterprise customers              | SOC 2 Type II                   |
| International company or customers explicitly requesting ISO | ISO/IEC 27001                   |
| Early-stage company needing a faster initial milestone       | SOC 2 Type I                    |
| Company selling internationally and to US enterprises        | Both                            |
| Customer explicitly requires one framework                   | Follow the customer requirement |

When both are required, the company should build one shared control system and map the same controls and evidence to both frameworks.

Do not implement two independent compliance systems.

---

## 4. Typical duration

There is no guaranteed duration.

| Target                               | Company with a reasonable security baseline | Company starting from weak or undocumented controls |
| ------------------------------------ | ------------------------------------------: | --------------------------------------------------: |
| SOC 2 Type I                         |                                  2–4 months |                                          4–8 months |
| SOC 2 Type II                        |                                  5–9 months |                                         9–15 months |
| ISO/IEC 27001                        |                                  4–8 months |                                         8–15 months |
| SOC 2 Type II and ISO 27001 together |                                 6–10 months |                                        10–18 months |

These estimates include preparation, remediation, evidence collection and the external audit.

They may increase because of:

* Large or unclear audit scope
* Multiple cloud environments or offices
* Weak access management
* Missing asset inventory
* Poor change traceability
* Undocumented vendors
* Missing policies
* Inconsistent evidence
* Auditor scheduling
* Major findings that require remediation

---

## 5. End-to-end roadmap

| Phase                        |    Typical duration | Main work                                                                    | Expected output                          |
| ---------------------------- | ------------------: | ---------------------------------------------------------------------------- | ---------------------------------------- |
| 1. Business decision         |              1 week | Select SOC 2, ISO 27001 or both                                              | Approved objective and executive sponsor |
| 2. Scope definition          |           1–2 weeks | Define products, systems, people, locations, vendors and data included       | Written scope                            |
| 3. Gap assessment            |           2–4 weeks | Compare current processes and controls against requirements                  | Gap register and remediation plan        |
| 4. Risk assessment           |           1–3 weeks | Identify assets, threats, risks and required treatments                      | Risk register and treatment plan         |
| 5. Control and policy design |           2–6 weeks | Define policies, procedures, owners and evidence                             | Control register and approved policies   |
| 6. Technical remediation     |          4–12 weeks | Implement IAM, logging, CI/CD, backup, vulnerability and monitoring controls | Working technical controls               |
| 7. Process operation         |          1–6 months | Perform reviews, tests, approvals and recurring activities                   | Evidence showing controls operate        |
| 8. Readiness review          |           1–3 weeks | Check controls and evidence before external audit                            | Readiness report and remaining actions   |
| 9. External audit            |           2–8 weeks | Auditor tests documentation, controls and evidence                           | SOC 2 report or ISO audit findings       |
| 10. Remediation              | Depends on findings | Correct audit findings                                                       | Accepted corrective actions              |
| 11. Continuous operation     |             Ongoing | Continue controls, reviews and evidence collection                           | Continued compliance and audit readiness |

Several phases normally run in parallel.

---

## 6. SOC 2 roadmap

### Step 1: Select the report type

* Use **Type I** to evaluate control design at one date.
* Use **Type II** when customers expect evidence that controls operated consistently over time.

Most mature enterprise customers prefer Type II.

### Step 2: Select applicable Trust Services Criteria

| Category             | Covers                                                          |
| -------------------- | --------------------------------------------------------------- |
| Security             | Protection against unauthorized access and security events      |
| Availability         | System availability and resilience commitments                  |
| Confidentiality      | Protection of confidential information                          |
| Processing Integrity | Complete, valid, accurate and timely processing                 |
| Privacy              | Collection, use, retention and disposal of personal information |

Do not add categories only for marketing. Include criteria that match customer commitments and actual company risks.

### Step 3: Define controls

Examples:

* Access approval and periodic access reviews
* Employee onboarding and offboarding
* Pull-request and production change approval
* Vulnerability scanning and remediation
* Logging and monitoring
* Incident response
* Backup and restore testing
* Vendor reviews
* Security training
* Risk review

### Step 4: Operate controls

Type II requires evidence that controls operated during the selected audit period.

Examples:

* Access-review records
* Approved pull requests
* Deployment logs
* Vulnerability reports
* Incident tickets
* Backup restore results
* Security-training records

### Step 5: External examination

A licensed and qualified CPA firm performs the SOC 2 examination and issues the report.

---

## 7. ISO/IEC 27001 roadmap

ISO 27001 focuses on establishing and continually improving an ISMS.

### Required management-system elements

The organization needs to establish:

* ISMS scope
* Information-security policy
* Risk-assessment methodology
* Risk register
* Risk-treatment plan
* Security objectives
* Control owners
* Statement of Applicability
* Internal audit
* Management review
* Corrective-action process
* Continual improvement

### Statement of Applicability

The Statement of Applicability records:

* Which controls apply
* Which controls do not apply
* Why controls were included or excluded
* How applicable controls are implemented

It should reflect actual risks and company operations, not a copied template.

### Certification audit

| Stage               | Purpose                                                             |
| ------------------- | ------------------------------------------------------------------- |
| Stage 1             | Review scope, ISMS documentation, readiness and major gaps          |
| Remediation         | Correct problems identified during Stage 1                          |
| Stage 2             | Verify that the ISMS and controls are implemented and operating     |
| Surveillance audits | Periodic checks after certification                                 |
| Recertification     | Full certification renewal, normally within the certification cycle |

The organization must perform an internal audit and management review before certification.

---

## 8. Small-company responsibility model

Example:

* CTO
* One or two DevOps/Platform engineers
* Application engineers
* HR or Operations
* External compliance consultant
* External auditor

| Area                                | Primary owner                            | Supporting roles                |
| ----------------------------------- | ---------------------------------------- | ------------------------------- |
| Executive sponsorship               | CTO                                      | Founders or management          |
| Scope and priorities                | CTO                                      | DevOps, Engineering, consultant |
| Compliance coordination             | CTO, Operations lead or named ISMS owner | Consultant and control owners   |
| Risk acceptance                     | CTO or executive management              | Security and technical leads    |
| Cloud and infrastructure controls   | DevOps / Platform                        | CTO                             |
| IAM and privileged access           | DevOps / Platform                        | HR and CTO                      |
| CI/CD and change management         | DevOps / Platform                        | Application Engineering         |
| Application security                | Engineering Lead                         | Developers and DevOps           |
| Vulnerability remediation           | Technical owner of affected system       | DevOps, Engineering, Security   |
| Logging and monitoring              | DevOps / Platform                        | Engineering                     |
| Backup and disaster recovery        | DevOps / Platform                        | CTO and business owners         |
| Incident response                   | CTO or technical lead                    | DevOps, Engineering, Operations |
| Employee onboarding and offboarding | HR / Operations                          | DevOps for technical access     |
| Security awareness training         | HR / Operations                          | CTO                             |
| Vendor management                   | CTO or Operations                        | Legal, DevOps and system owners |
| Policies                            | Relevant process owner                   | CTO and consultant              |
| Evidence collection                 | Each control owner                       | Compliance coordinator          |
| Internal readiness review           | Consultant or independent reviewer       | All control owners              |
| External assessment                 | Independent auditor                      | Entire company                  |

In a small company, one person may hold several roles, but ownership must still be explicit.

DevOps should not silently become the owner of HR, Legal, vendor risk, policies and company-wide risk acceptance.

---

## 9. Larger-company responsibility model

| Role or team              | Main responsibility                                                                       |
| ------------------------- | ----------------------------------------------------------------------------------------- |
| CTO, CIO or CISO          | Executive sponsorship, budget and risk acceptance                                         |
| GRC / Compliance          | Program coordination, control mapping, policies, evidence tracking and audit coordination |
| Security Engineering      | Security architecture, detection, vulnerability management and incident support           |
| Platform / DevOps / SRE   | Cloud, IAM implementation, CI/CD, infrastructure security, logging, backup and recovery   |
| Application Engineering   | Secure development, application vulnerabilities and application-level controls            |
| AppSec                    | Secure development guidance, threat modelling, SAST/DAST and application-security testing |
| IT / Identity             | Employee accounts, SSO, MFA, devices and workforce access                                 |
| HR                        | Hiring, onboarding, offboarding, training and policy acknowledgement                      |
| Legal / Privacy           | Contracts, data protection, privacy requirements and regulatory interpretation            |
| Procurement / Vendor Risk | Vendor assessment, contracts and recurring vendor reviews                                 |
| Business Continuity       | Business impact analysis, recovery planning and exercises                                 |
| Internal Audit            | Independent review of the ISMS and controls                                               |
| External auditor          | Independent SOC 2 examination or ISO certification audit                                  |

---

## 10. What DevOps normally owns

DevOps or Platform usually owns or operates:

* Infrastructure as Code
* Cloud-account security
* Production access
* SSO and MFA implementation
* Role-based access
* Secrets management
* CI/CD security
* Change traceability
* Branch protection
* Deployment records
* Infrastructure vulnerability management
* Container and dependency scanning infrastructure
* Central logging
* Monitoring and alerting
* Backup automation
* Restore testing
* Technical incident-response procedures
* Infrastructure inventory
* Technical audit evidence

DevOps may support but should not solely own:

* Company risk acceptance
* HR processes
* Legal and privacy interpretation
* Vendor contracts
* Employee training
* All security policies
* Internal audit
* External certification decisions

---

## 11. Minimum technical baseline

Before audit readiness, the company should normally have:

| Area             | Expected baseline                                             |
| ---------------- | ------------------------------------------------------------- |
| Identity         | SSO, MFA, least privilege and controlled administrator access |
| Access lifecycle | Documented onboarding, role changes and offboarding           |
| Infrastructure   | Version-controlled Infrastructure as Code where practical     |
| Source control   | Protected branches, reviews and traceable changes             |
| CI/CD            | Controlled deployments and retained execution history         |
| Secrets          | Central secrets manager; no secrets in source control         |
| Vulnerabilities  | Regular scanning, ownership and remediation targets           |
| Logging          | Centralized logs with defined retention                       |
| Monitoring       | Alerts with owners and escalation paths                       |
| Incidents        | Incident process, severity levels and post-incident review    |
| Backups          | Defined backups and periodically tested restores              |
| Assets           | Inventory of systems, services, devices and critical vendors  |
| Vendors          | Security review for important service providers               |
| Evidence         | Repeatable storage of audit evidence                          |

---

## 12. Evidence examples

| Control                  | Example evidence                            |
| ------------------------ | ------------------------------------------- |
| Access approval          | Approved ticket or workflow                 |
| Access review            | Completed quarterly review                  |
| Employee termination     | HR record and account-disable logs          |
| Change management        | Approved pull request and deployment record |
| Vulnerability management | Scan result and remediation ticket          |
| Backup control           | Backup status and restore-test report       |
| Incident response        | Incident timeline and postmortem            |
| Security training        | Completion report                           |
| Vendor management        | Vendor questionnaire and approval           |
| Risk management          | Risk-register review and treatment decision |
| Management review        | Meeting minutes and recorded decisions      |

Screenshots should be a last resort. Prefer durable system records, tickets, logs and exported reports.

---

## 13. Common reasons projects fail

* No executive sponsor
* Compliance treated as a DevOps-only project
* Scope is too large or undefined
* Policies copied from templates but not followed
* Controls exist but no evidence is retained
* Evidence is collected manually at the last minute
* Employees bypass documented processes
* No owner is assigned to each control
* Risks are discovered but never formally accepted or treated
* Audit automation tooling is mistaken for actual compliance
* Internal audit is performed by the same person who operates every control
* Certification is promised to customers before audit completion

---

## 14. Recommended practical approach

For a smaller engineering company:

1. Appoint the CTO as executive sponsor.
2. Name one compliance or ISMS coordinator.
3. Keep the first scope limited to the production service and supporting systems.
4. Engage an experienced adviser for the initial gap assessment.
5. Build one shared control register for SOC 2 and ISO 27001.
6. Assign an owner to every control.
7. Automate technical evidence where practical.
8. Run controls consistently before the audit.
9. Perform an independent readiness review.
10. Engage the external auditor only when major gaps are resolved.

The goal is not to produce documents for an auditor.

The goal is to build security processes that the company actually follows and can prove.
