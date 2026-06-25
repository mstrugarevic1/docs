# CI/CD Standards

This document defines the standard structure, quality gates, and deployment practices for CI/CD pipelines.

## Pipeline Principles

*   **Consistency:** All pipelines should follow a similar structure.
*   **Security:** Secrets are never stored in Git; scans are integrated.
*   **Feedback:** Pipelines should fail fast and provide clear errors.
*   **Automation:** Deployments to non-production should be fully automated.

## Branching & Pull Requests

*   **Main-based Development:** Feature branches merge into `main`.
*   **Short-lived Branches:** Merge at least every 2-3 days.
*   **PR Rules:** Require at least one approval and passing CI checks.

## Recommended Pipeline Flow

```text
Commit -> Build -> Test -> Scan -> Package -> Deploy to Dev -> Promote -> Deploy to Production
```

## Pipeline Stages

### 1. Build
- Compile code and install dependencies.
- Linting (Style, Syntax, Static Analysis).

### 2. Test
- Unit tests (minimum code coverage required).
- Integration tests (mocked external dependencies).

### 3. Scan
- SAST (Static Application Security Testing).
- Dependency vulnerability scanning (SCA).
- Secret scanning in the repository.

### 4. Package
- Container image creation (Dockerfile).
- Image signing and pushing to a private registry.

### 5. Deploy & Promote
- **Deployment:** Use the **exact same artifact** across all environments.
- **Approval Gates:** Manual or automated gate for Production based on Staging success.

#### Deployment Monitoring Downtime

For deployments that may cause expected restarts or temporary service degradation, it is a recommended practice to optionally automate a maintenance window or monitoring downtime directly from the pipeline. This reduces false-positive alerts and unnecessary on-call notifications during the rollout phase.

* May be configured in the monitoring platform or incident/on-call management tool.
* Should target only the affected service or service group.
* Should start immediately before the deployment process begins.
* Must have an automatic expiration.
* Should be removed after successful deployment validation.
* Must not suppress unrelated or critical infrastructure alerts.

## Secrets Handling

> [!WARNING]
> Secrets must not be stored in Git, pipeline logs, or plain-text pipeline variables. Use a dedicated secret manager and inject them at runtime.

## Pipeline Observability

- Track pipeline success rates and duration.
- Ensure deployment events are sent to central observability tools.
