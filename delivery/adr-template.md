# ADR Template

This document records the context, decision, tradeoffs, and expected consequences of an important technical decision.

## Blank Template

# ADR-0000: <Decision title>

| Field | Value |
|---|---|
| Status | Proposed / Accepted / Deprecated / Superseded |
| Date | YYYY-MM-DD |
| Owner | <name/team> |
| Related | <tickets/PRs/docs> |

## Context

Describe the situation that led to the decision.

Include:
- what problem exists
- why the decision is needed now
- what limitations or pain points exist
- what happens if no decision is made

## Goals

List what this decision should achieve.

## Non-Goals

List what is intentionally out of scope.

## Constraints

Mention relevant constraints such as existing systems, cost, security, compliance, team capacity, operational complexity, timeline, or backwards compatibility.

## Options Considered

| Option | Description | Advantages | Disadvantages | Risks |
|---|---|---|---|---|
| Option A | ... | ... | ... | ... |
| Option B | ... | ... | ... | ... |
| Option C | ... | ... | ... | ... |

## Decision

Clearly state the selected option.

The decision should be specific enough that a reader understands what will be done.

## Reasoning

Explain why this option was selected.

Include:
- main tradeoffs
- why other options were rejected
- what complexity is being accepted
- why the decision makes sense in the current context

## Consequences

Positive consequences:
- ...

Negative consequences:
- ...

New complexity:
- ...

## Operational Impact

Describe how the decision affects day-to-day operation.

Include only what is relevant:
- deployment
- monitoring
- alerting
- logging
- incident response
- runbooks
- on-call impact

## Security and Compliance Impact

Describe any security or compliance impact.

If there is no known impact, write:

No direct security or compliance impact identified.

## Cost Impact

Optional. Include if the decision has noticeable infrastructure, licensing, or operational cost impact.

## Rollout Plan

Briefly describe how the decision will be introduced safely.

## Rollback Plan

Briefly describe how to recover if the decision causes problems.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| ... | ... | ... |

## Success Criteria

Describe how the team will know the decision worked.

## Related Documents

Links to related tickets, pull requests, runbooks, dashboards, incidents, previous ADRs, or vendor documentation.

## Superseded By

Optional. Use this if a newer ADR replaces this decision.

---

## Example

# ADR-0001: Use SQS with DLQ for asynchronous partner synchronization

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2023-10-15 |
| Owner | Alex Doe |
| Related | TICKET-123, PR-456 |

## Context

Our core API synchronously forwards requests to a partner service. The partner service has degraded reliability and occasionally times out. These timeouts block API requests, leading to failed customer operations and resource starvation in our service. If no decision is made, customer errors will continue to spike during partner downtime.

## Goals

- Isolate our core API from partner service outages
- Ensure customer requests succeed even if the partner service is temporarily unavailable
- Retain all requests for eventual processing

## Non-Goals

- Real-time synchronization with the partner service

## Constraints

- Must not lose any synchronization events
- Cost must remain under existing cloud budget
- Must handle temporary partner outages of up to 4 hours

## Options Considered

| Option | Description | Advantages | Disadvantages | Risks |
|---|---|---|---|---|
| Synchronous retries | Implement retries with exponential backoff directly within the API handler. | Simple to implement, no new infrastructure required. | API still blocks during retries, does not solve resource starvation during extended outages. | Connection pool exhaustion during prolonged downtime. |
| Use SQS with DLQ | Push requests to an SQS queue and process them with a separate background worker. | Fully decouples the API from the partner service, natively handles retries and long outages. | Adds infrastructure complexity, requires a new background worker service. | Messages could be processed out of order. |
| EventBridge | Use EventBridge to route events to a target handler. | Serverless routing, easy to extend with multiple targets. | Higher latency, more complex DLQ management compared to standard SQS. | Potential payload size limits. |

## Decision

Use SQS with a Dead Letter Queue (DLQ) for asynchronous processing.

## Reasoning

SQS provides the simplest and most robust way to decouple our API from the partner service, avoiding direct dependency on an external API. It guarantees delivery and handles retry behavior and extended outages natively. We reject synchronous retries because they do not protect against prolonged downtime. The added operational complexity of maintaining a worker service is accepted to achieve the required reliability.

## Consequences

Positive consequences:
- Core API latency is no longer affected by partner service performance
- Partner outages do not cause customer-facing errors

Negative consequences:
- Synchronization is strictly asynchronous

New complexity:
- A new background worker service must be deployed and maintained
- SQS queues and DLQs must be monitored

## Operational Impact

- Monitoring: Need metrics for SQS queue depth and worker processing latency.
- Alerting: Alert if the DLQ receives messages or if queue depth exceeds 10,000 for more than 5 minutes.
- Runbooks: Create a runbook for inspecting and redriving DLQ messages.

## Security and Compliance Impact

No direct security or compliance impact identified.

## Cost Impact

Minor increase due to SQS request pricing and small compute resources for the worker service. Expected to be under $50/month.

## Rollout Plan

1. Provision SQS and DLQ infrastructure.
2. Deploy the worker service to consume from SQS and call the partner service.
3. Update the core API to write to SQS instead of calling the partner synchronously, behind a feature flag.
4. Gradually enable the feature flag for a subset of traffic.

## Rollback Plan

1. Disable the feature flag to revert the core API to synchronous calls.
2. Allow the worker to drain any remaining messages in SQS. This provides a safe rollback to the previous flow if needed.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Messages are processed more than once | Duplicate actions in partner system | Implement idempotency keys for partner requests |
| External API is unavailable for extended period | Processing delay, queue fills up | Native SQS retry behavior with backoff, monitor queue depth, move to DLQ on failure |
| Poison pill messages crash worker | Worker starvation | Move failed messages to DLQ after 3 retries, monitor failed messages |

## Success Criteria

- Zero customer-facing errors caused by partner service timeouts
- Partner outages are invisible to the core API
- DLQ alerts fire correctly during extended partner downtime

## Related Documents

- TICKET-123
- Partner API Documentation

## Superseded By

(None)
