# AI-Assisted Development of Existing Applications

## 1. Purpose

This guide describes a practical workflow for using an AI coding agent while extending an existing production application. It is meant for work that continues across multiple tickets, multiple AI sessions, or more than one engineer.

The main objective is to preserve development context between:
- Feature A and Feature B
- one engineer and another engineer
- one AI session and a later AI session

AI chat history must not be the only place where project knowledge exists. Important context should live in the repository, close to the code, so future work can start from verified facts instead of repeating a full repository investigation.

This is not a greenfield architecture guide, a modernization framework, or a reason to document every trivial change. The preferred approach is the smallest safe change that fits the current application.

## 2. Example Scenario

The example used throughout this guide is an `Internal ChatOps Bot` that communicates with an incident-management provider.

The bot currently supports operations such as:
- retrieving the current on-call engineer
- working with on-call schedules or overrides
- starting a temporary maintenance or downtime window during deployments
- suppressing selected notifications while maintenance is active
- restoring normal notification behavior after deployment
- displaying basic schedule or alert information

The application currently uses `Provider A`. The organization needs to introduce `Provider B`. During the migration, both providers must work simultaneously.

The migration should:
- preserve all existing `Provider A` behavior
- introduce `Provider B` incrementally
- allow different teams or environments to use different providers
- preserve existing commands and user-facing output where possible
- follow the current repository structure
- follow the existing coding style
- reuse existing libraries and patterns
- avoid unrelated refactoring
- avoid introducing a new framework
- avoid creating a new architecture without a demonstrated need
- preserve existing configuration and secret-handling conventions
- avoid logging credentials, tokens, personal data, or complete external API payloads
- preserve deployment and rollback behavior
- allow configuration-based rollback to `Provider A` where practical

The correct approach is not necessarily the theoretically cleanest architecture. The right first step is the smallest coherent change that protects existing behavior and makes the next ticket easier.

## 3. Development Constraints

Use these constraints for every ticket in the migration:
- Preserve current behavior unless the ticket explicitly changes it.
- Follow existing code patterns.
- Make the smallest coherent change.
- Modify only files required by the approved plan.
- Do not perform opportunistic cleanup.
- Do not reformat unrelated files.
- Do not introduce dependencies without approval.
- Do not create a new abstraction merely because one looks cleaner.
- Do not expose sensitive data.
- Separate verified facts from assumptions.
- Stop and explain when the requested feature requires broader architectural work.

These constraints keep the AI agent useful without letting it expand the ticket into an unplanned rewrite.

## 4. Context Stored in the Repository

This is an example structure, not a mandatory convention:

```text
docs/
|-- system-context.md
|-- decisions/
|   `-- 001-provider-migration-strategy.md
|-- features/
|   |-- DEVOPS-101-provider-boundary.md
|   |-- DEVOPS-102-provider-b-on-call-lookup.md
|   `-- DEVOPS-103-provider-b-maintenance-window.md
|-- work-in-progress/
|   `-- DEVOPS-104-provider-routing.md
`-- changelog.md
```

Purpose of each type:
- `system-context.md`: stable facts about the `Internal ChatOps Bot`, important commands, runtime behavior, configuration patterns, deployment notes, and known integration boundaries.
- `decisions/`: decisions affecting multiple tickets, such as the migration strategy or provider-selection approach.
- `features/`: completed ticket context, including what changed, what was tested, what assumptions were accepted, and what future work should know.
- `work-in-progress/`: an active checkpoint used to continue later in a new AI session or by another engineer.
- `changelog.md`: short operational or user-visible changes.

Do not create a separate permanent PR review document for every pull request. Important review conclusions can be stored in the relevant feature note or decision record.

## 5. Initial Repository Review

Before migration work begins, ask the AI agent to inspect the current application and identify the real flow. During this step, the agent must not modify code.

The AI agent should identify:
- application entry points
- command handlers
- `Provider A` client and API calls
- business-logic or service boundaries
- configuration and secret loading
- error handling
- retries and timeouts
- logging conventions
- existing tests and mocks
- deployment configuration
- every relevant direct dependency on `Provider A`

Example prompt:

```text
Inspect the repository for the Internal ChatOps Bot migration from Provider A to Provider B.
Do not modify files.
Identify exact paths, functions, classes, commands, configuration keys, tests, mocks, and direct Provider A dependencies.
Separate verified facts from assumptions and keep the findings concise.
```

The output from this review should become the initial system context or the starting section of the first feature note.

## 6. Feature-by-Feature Migration

Split the migration into independently testable tickets:

```text
DEVOPS-101 - Isolate Provider A behind the smallest useful boundary
DEVOPS-102 - Add Provider B read-only on-call lookup
DEVOPS-103 - Add Provider B maintenance-window support
DEVOPS-104 - Add configuration-based provider routing
```

`DEVOPS-101` creates the smallest boundary needed to stop command handlers from depending directly on `Provider A` details. It should preserve `Provider A` behavior and avoid a large provider framework.

`DEVOPS-102` adds `Provider B` support for read-only on-call lookup. Read-only behavior is a safer first integration step because it does not create external state.

`DEVOPS-103` adds `Provider B` maintenance-window support. This is higher risk because it creates or changes external state, so error handling, retries, idempotency, and rollback behavior matter more.

`DEVOPS-104` adds configuration-based provider routing so different teams or environments can use different providers. Routing should come after the underlying operations exist.

Keep one independently testable change per ticket. `Provider A` must remain functional throughout the migration. A feature ticket should not hide a large refactor.

## 7. Feature Development Lifecycle

Use this lifecycle for each ticket:

```text
Feature Request
-> Load Existing Context
-> Targeted Repository Review
-> Feature Plan
-> Human Approval
-> AI-Assisted Implementation
-> Local Testing
-> AI-Assisted Review
-> Human Review
-> Merge and Deploy
-> Post-Deployment Verification
-> Update Feature Context
-> Context Available to the Next Ticket
```

Step summary:
- Feature Request: capture the ticket goal, acceptance criteria, constraints, and rollback expectations.
- Load Existing Context: read repository instructions, system context, relevant decisions, related feature notes, and any active work-in-progress checkpoint.
- Targeted Repository Review: inspect only the code paths relevant to the current ticket and compare repository state with the saved context.
- Feature Plan: ask the AI agent for the smallest implementation plan, expected files, test plan, compatibility risks, and rollback implications.
- Human Approval: the engineer reviews the plan before implementation starts.
- AI-Assisted Implementation: the AI agent makes the approved change while the engineer owns the result.
- Local Testing: run relevant tests and validation. Failed tests return the work to implementation.
- AI-Assisted Review: inspect the final diff against the request and plan. Review changes return the work to implementation and testing.
- Human Review: the engineer accepts or rejects the change based on correctness, supportability, and risk.
- Merge and Deploy: deploy through the normal process.
- Post-Deployment Verification: verify the deployed behavior. A failed deployment or verification can trigger rollback.
- Update Feature Context: finalize the completed feature note only after verification.
- Context Available to the Next Ticket: the next ticket starts from saved context rather than rediscovering everything.

Feature Plan comes before Human Approval. Implementation starts only after the plan is approved.

## 8. Feature Context Template

Use a feature note or work-in-progress checkpoint to record only the context needed to understand and continue the work. Do not duplicate the implementation.

```markdown
# DEVOPS-XXX: Feature Name

## Objective

## Starting Context

## Relevant Previous Work

## Relevant Code

## Constraints

## Approved Plan

## Files Expected to Change

## Implementation Progress

## Files Changed and Why

## Tests Executed

- Passed:
- Failed:
- Not executed:
- Blocked:

## Decisions and Assumptions

## Known Gaps

## Current Git State

## Exact Next Step

## Deployment and Rollback

## Final Result
```

Never state that tests passed unless they were actually executed. If tests were skipped, failed, or blocked, record that plainly.

## 9. Continuing in a New AI Session

Before ending a session, save enough state for another session to continue without guessing:
- current branch
- latest relevant commit
- modified and untracked files
- completed work
- incomplete work
- exact next coding step
- tests executed and results
- known failures
- temporary assumptions
- unresolved questions
- constraints that must remain unchanged

Session-end prompt:

```text
Update the active work-in-progress document for DEVOPS-XXX using the current repository and Git state as the source of truth.
Record the current branch, latest relevant commit, modified and untracked files, completed work, incomplete work, exact next step, tests executed with results, known failures, assumptions, unresolved questions, and constraints that must not change.
Do not claim tests passed unless the commands were actually executed.
```

Next-session prompt:

```text
Continue DEVOPS-XXX.
First read repository instructions, docs/system-context.md, relevant decision records, directly related completed feature notes, and the active work-in-progress checkpoint.
Then inspect git status, git diff, and only the implementation files relevant to this ticket.
Compare the checkpoint with the actual repository state.
Report what is complete, what remains, any conflicts between documentation and Git state, and the next recommended step.
Wait for approval before modifying files if documentation and Git state conflict.
```

The saved checkpoint reduces repeated discovery, but it does not replace verification against the current code and Git state.

## 10. Starting the Next Ticket

The next ticket should not load the complete repository history. Load context in layers.

Always read:
- repository-level agent instructions
- stable system context
- active work-in-progress context

Read when relevant:
- directly related feature notes
- applicable decision records
- deployment or operational documentation

Inspect directly:
- current Git state
- implementation files relevant to the ticket
- relevant tests
- configuration affected by the change

Prompt for a related ticket:

```text
Start DEVOPS-104 for configuration-based provider routing in the Internal ChatOps Bot.
Before modifying code, read the stable system context, Provider A to Provider B migration decision, DEVOPS-101 through DEVOPS-103 feature notes, and any active work-in-progress checkpoint.
Inspect git status, git diff, relevant provider-selection code, command handlers, tests, and configuration.
Return your understanding of the current implementation, existing patterns that must remain, exact files likely to change, compatibility risks, implementation plan, test plan, and rollback implications.
Do not modify files yet.
```

This keeps the AI agent focused on the current ticket while still preserving the history that matters.

## 11. Validation and Deployment

Local validation should record exact commands and actual results.

For a dual-provider migration, cover the scenarios relevant to the ticket:
- `Provider A` selected
- `Provider B` selected
- missing provider configuration
- invalid provider configuration
- expected external API failure
- provider timeout or unavailability where practical
- unchanged user-facing behavior
- configuration-based rollback

After deployment, record:
- version or commit
- environment
- deployment result
- smoke tests
- relevant logs, metrics, or dashboard observations
- unexpected behavior
- rollback status
- follow-up work

Deployment is not complete until post-deployment verification is performed. If verification fails, use the agreed rollback path, such as switching configuration back to `Provider A` where practical.

## 12. Workflow Diagram

![Legacy application development workflow](images/ai-assisted-feature-development-flow.png)

## 13. Expected Result

After the migration work has been documented well, a future engineer or AI agent should be able to answer:
- Why are two providers supported?
- Which provider is currently the default?
- How is the provider selected?
- Which `Provider B` capabilities are complete?
- Which existing behavior must remain unchanged?
- Which decisions were deliberate?
- Which files are relevant?
- What was completed in the previous session?
- What is the exact next step?
- How is the feature tested?
- How is it deployed and rolled back?

Context preservation has failed if these answers require searching old AI chat transcripts or repeating a full repository investigation.
