# AI-Assisted Development

## Purpose

This document describes a practical approach to AI-assisted software development. It focuses on providing useful context, limiting the scope of changes, validating generated code, and keeping the engineer responsible for the final result.

It is a personal working guide, not an official standard. The goal is to make AI coding tools useful without letting them make unreviewed architecture, security, or production decisions.

## What AI Coding Tools Help With

LLMs and AI coding agents can help with:
- reading and summarizing repository structure
- explaining unfamiliar code
- proposing implementation plans
- drafting small code or documentation changes
- adding or improving tests
- reviewing diffs for bugs, missing tests, and unnecessary changes
- summarizing errors, logs, and command output

CLI agents can inspect local files, propose plans, modify files, and run commands when allowed. That access is useful, but generated output can be wrong, incomplete, or based on bad assumptions.

> [!NOTE]
> Treat AI output as a draft. Review it against the repository, tests, documentation, and the actual behavior of the system.

## Repository Context

AI tools work better when the repository contains durable context that can be read without reconstructing everything from scratch.

Useful context files include:
- `README.md`
- repository instructions such as `GEMINI.md`
- `docs/*.md`
- ADRs
- runbooks
- troubleshooting notes
- changelogs and feature notes

A repository-level instruction file is normally placed at the root, while component-specific instructions may also exist in relevant subdirectories.

Repository instructions can include:
- project structure
- build and test commands
- architecture constraints
- coding conventions
- files or directories that should not be modified
- deployment and validation requirements
- commands that require approval

They should not include:
- secrets
- passwords
- tokens
- private credentials
- temporary personal notes
- large duplicated documentation

Example:

```markdown
# Repository Instructions

## Project Shape

- Python service with tests under `tests/`
- API code under `src/api/`
- Background jobs under `src/jobs/`

## Commands

- Run tests: `pytest`
- Run linting: `ruff check .`
- Format: `ruff format .`

## Change Rules

- Keep changes small and reviewable.
- Reuse existing patterns before adding new ones.
- Do not modify deployment files without approval.
- Add or update tests when behavior changes.
- Do not store secrets in documentation, prompts, or test fixtures.
```

## Instructions, Skills, and MCP

These are different kinds of context and capability:

- Repository instructions: persistent project context and constraints stored with the repository.
- Skills: reusable task-specific procedures that can be loaded when relevant.
- MCP servers: controlled access to external tools or data sources.

Practical MCP examples include:
- issue tracker access for ticket context
- documentation lookup for current API behavior
- cloud inventory for read-only resource discovery
- source-control metadata for commits, branches, pull requests, and reviews

External access should follow least privilege. Avoid exposing unnecessary credentials, secrets, or production-changing access. Read-only access is usually enough for discovery and planning.

## Execution Controls

Before allowing an AI agent to modify files or run commands:
- ask it to inspect relevant context first
- ask for a short plan before implementation
- limit changes to the current repository or directory
- review commands before execution
- use sandboxing where available
- use approval modes where available
- avoid automatic access to secrets
- keep changes small enough to review in one sitting

These controls are not a heavy process. They are guardrails that make the final diff easier to understand and safer to own.

## General Workflow

Use this compact loop for most AI-assisted changes:

1. Understand the request.
2. Inspect relevant context.
3. Propose a plan.
4. Confirm scope.
5. Implement the smallest useful change.
6. Run tests and validation.
7. Review the final diff.
8. Record useful durable context.

For inherited or legacy applications, use the companion workflow in `legacy-application-development.md`.

## Prompt Examples

Good prompts are specific about objective, scope, constraints, and validation.

```text
Read the repository instructions, README, and files under `src/billing/`.
Summarize the current billing export flow and list likely files for this change.
Do not modify files.
```

```text
Plan a minimal change for replacing the deprecated export API in `src/billing/`.
Reuse existing patterns, list expected files, identify tests to update, and include rollback notes.
Do not write code yet.
```

```text
Implement the approved plan only.
Do not refactor unrelated code.
Run the relevant tests and summarize the final diff.
```

```text
Review this diff against the acceptance criteria, existing architecture, test coverage, security risks, production impact, and rollback approach.
Report issues without modifying files.
```

Bad prompts hide scope or skip review.

```text
Fix everything.
```

```text
Rewrite this project.
```

```text
Make it production ready.
```

```text
Run whatever commands you need and commit the result.
```

## AI Review

AI review is most useful after tests have run and the final diff exists.

Ask the AI agent to:
- inspect the final diff
- compare the result with the original request
- look for unnecessary changes
- identify missing tests
- check compatibility risks
- call out failure paths and rollback concerns
- report findings without rewriting the implementation automatically

A fresh AI session may reduce the chance of repeating assumptions made during implementation. It still does not replace human review.

## Practical Checklist

- Request understood.
- Relevant context inspected.
- Plan reviewed.
- Scope limited.
- Unrelated files untouched.
- Tests or validation executed.
- Failure paths considered.
- Final diff reviewed.
- Secrets not exposed.
- Useful durable context documented.
