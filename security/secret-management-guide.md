# Secret Management Guide

Practical guide for managing secrets in three common infrastructure workflows:

1. Ansible Vault for Ansible-specific secrets.
2. Terraform with AWS Secrets Manager or AWS SSM Parameter Store.
3. Terraform with HashiCorp Vault.

Audience: DevOps / Platform Engineers. Focus: setup, usage, rekey/rotation, maintenance, common mistakes, and safe operational patterns.

All secret values in this document are fake placeholders (`change-me`, `example-password`, `dummy-token`).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Secrets Management Rules of Thumb](#2-secrets-management-rules-of-thumb)
3. [Ansible Vault](#3-ansible-vault)
4. [Ansible Vault Maintenance and Rekey](#4-ansible-vault-maintenance-and-rekey)
5. [Terraform and Secrets](#5-terraform-and-secrets)
6. [Terraform with AWS Secrets Manager](#6-terraform-with-aws-secrets-manager)
7. [Terraform with AWS SSM Parameter Store](#7-terraform-with-aws-ssm-parameter-store)
8. [Terraform with HashiCorp Vault](#8-terraform-with-hashicorp-vault)
9. [CI/CD Usage Patterns](#9-cicd-usage-patterns)
10. [Rotation vs Rekey vs Redeploy](#10-rotation-vs-rekey-vs-redeploy)
11. [Common Mistakes](#11-common-mistakes)
12. [Recommended Decision Matrix](#12-recommended-decision-matrix)
13. [Final Interview-Ready Summary](#13-final-interview-ready-summary)
14. [Appendix: Command Cheat Sheets](#appendix-command-cheat-sheets)

---

## 1. Overview

These tools solve different problems and are often confused:

| Tool | What it is | Scope |
|---|---|---|
| Ansible Vault | Encryption for files and variables inside an Ansible repository | Ansible only |
| AWS Secrets Manager | Managed AWS secret store with versioning and rotation support | AWS |
| AWS SSM Parameter Store | Hierarchical key/value store with optional `SecureString` encryption | AWS |
| HashiCorp Vault | Centralized secrets management system with auth methods, policies, and dynamic credentials | Any platform |
| Terraform `sensitive = true` | Output masking flag for Terraform variables and outputs | Terraform CLI output only |

Key points:

> Terraform should usually manage secret containers, references, IAM permissions, and wiring. It should avoid managing raw secret values where possible.

> Ansible Vault encrypts files or variables in an Ansible repository. It is not the same as HashiCorp Vault. Ansible Vault is encrypted file storage; HashiCorp Vault is a running secrets management service.

> Terraform `sensitive = true` only masks values in CLI output. It does not remove them from state or plan files.

---

## 2. Secrets Management Rules of Thumb

- Do not commit plaintext secrets to Git. Git history keeps them forever.
- Do not pass secrets directly in CLI commands if they can end up in shell history.
- Do not expose secrets in CI logs. CI logs are a common leak path.
- Use least privilege for humans, CI/CD, and applications. Each should only read the secrets it needs.
- Prefer short-lived credentials (OIDC, dynamic Vault credentials, IAM roles) over static long-lived keys.
- Prefer runtime secret retrieval over baking secrets into infrastructure code.
- Protect Terraform state. It can contain sensitive data and must be treated as sensitive itself.
- Rotate actual secrets separately from rotating encryption passwords or vault keys. These are different operations with different blast radius.

---

## 3. Ansible Vault

Ansible Vault encrypts files or individual values inside an Ansible repository so secrets can live in Git safely. Typical use cases:

- Database passwords used by Ansible templates.
- API tokens used during automation.
- SSH keys used by deployment automation.
- Application config values that are not suitable for plaintext Git.

### Project structure

```text
ansible/
├── inventory.ini
├── playbook.yml
├── group_vars/
│   └── prod/
│       ├── vars.yml
│       └── vault.yml
└── .gitignore
```

The pattern:

- `vars.yml` contains normal variables and stays readable.
- `vault.yml` contains encrypted secret variables.
- Normal variables reference vaulted variables, so `grep` and code review still work on `vars.yml`.

`group_vars/prod/vars.yml`:

```yaml
app_name: myapp
db_user: app
db_password: "{{ vault_db_password }}"
```

`group_vars/prod/vault.yml` before encryption:

```yaml
vault_db_password: "change-me"
api_token: "dummy-token"
```

### Encrypting and working with vault files

```bash
ansible-vault encrypt group_vars/prod/vault.yml
ansible-vault view group_vars/prod/vault.yml
ansible-vault edit group_vars/prod/vault.yml
```

Run a playbook with an interactive password prompt:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

Run with a password file:

```bash
ansible-playbook -i inventory.ini playbook.yml --vault-password-file .vault_pass
```

The password file must never be committed. Add it to `.gitignore`:

```gitignore
.vault_pass
*.vault_pass
```

### Using vaulted variables in a playbook

```yaml
- name: Configure application
  hosts: prod
  become: true

  tasks:
    - name: Write application config
      ansible.builtin.copy:
        dest: /etc/myapp/config.env
        mode: "0600"
        content: |
          APP_NAME={{ app_name }}
          DB_USER={{ db_user }}
          DB_PASSWORD={{ db_password }}
```

Notes:

- Use `mode: "0600"` for files containing secrets.
- Do not print vaulted variables with `ansible.builtin.debug`. Task output ends up in logs.
- Add `no_log: true` on tasks that handle secret values if their module output could contain them.

---

## 4. Ansible Vault Maintenance and Rekey

Two different operations are often confused:

- **Rekey**: change the password used to encrypt/decrypt the vault file.
- **Rotation**: change the actual secret value stored inside the file.

> `ansible-vault rekey` changes the password used to decrypt the vault file. It does not change the secret values stored inside the file. After a rekey, the database password is still the same database password.

### Rekey commands

```bash
ansible-vault rekey group_vars/prod/vault.yml
```

Non-interactive, with old and new password files:

```bash
ansible-vault rekey group_vars/prod/vault.yml \
  --vault-password-file old.vault_pass \
  --new-vault-password-file new.vault_pass
```

Multiple files at once:

```bash
ansible-vault rekey group_vars/prod/vault.yml group_vars/staging/vault.yml
```

### Encrypting a single value

Instead of a whole file, a single variable can be encrypted inline:

```bash
ansible-vault encrypt_string 'change-me' --name 'vault_db_password'
```

The output block is pasted directly into a vars file.

### Rotating the actual secret value

```bash
ansible-vault edit group_vars/prod/vault.yml
```

After changing the secret value, run the playbook or redeploy/restart the affected service. Editing the vault file alone changes nothing on the target systems.

### Maintenance checklist

- Rotate the vault password when someone leaves the team.
- Rotate actual application secrets according to the security policy.
- Remove old vault password files from CI/CD secret stores.
- Confirm the new vault password works in CI/CD before deleting the old one.
- Confirm affected services were redeployed if actual secrets changed.
- Audit the repository for accidental plaintext secrets.

---

## 5. Terraform and Secrets

Terraform has a `sensitive` flag for variables and outputs:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

> `sensitive = true` hides values from normal CLI output, but it does not guarantee the value is absent from Terraform state or plan files. Anyone with access to the state file can read the value.

Because of this, Terraform state must be treated as sensitive data. Safe principles:

- Use remote state (for example S3 with locking).
- Encrypt state at rest.
- Restrict access to state with IAM and bucket policies.
- Avoid storing raw secret values in Terraform when possible.
- Prefer managing secret metadata and permissions in Terraform, while applications retrieve values at runtime.

### Bad example

```hcl
resource "aws_db_instance" "main" {
  identifier = "app-db"
  username   = "app"
  password   = var.db_password
}
```

The password is now in the Terraform state file, and possibly in plan files. Everyone with state access can read it, and it persists across state versions.

### Better pattern

```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "prod/myapp/db/password"
}

output "db_password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
```

Terraform creates the secret container and returns the ARN. The actual value is written through a secure operational process (console, CLI with care, or rotation Lambda), and the application reads it at runtime. Terraform state only contains the ARN, which is not sensitive.

---

## 6. Terraform with AWS Secrets Manager

Use AWS Secrets Manager for:

- Application secrets.
- Database credentials.
- API keys.
- Secrets that need managed rotation (built-in rotation with Lambda).
- Runtime retrieval from AWS workloads (ECS, EKS, Lambda, EC2).

### Secret metadata (safe)

```hcl
resource "aws_secretsmanager_secret" "app_db" {
  name        = "prod/myapp/db"
  description = "Database credentials for myapp"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

### Secret version (use with caution)

Terraform can also write the value, but this puts it into state:

```hcl
resource "aws_secretsmanager_secret_version" "app_db" {
  secret_id = aws_secretsmanager_secret.app_db.id

  secret_string = jsonencode({
    username = "app"
    password = var.db_password
  })
}
```

> Use `aws_secretsmanager_secret_version` with caution. If Terraform manages `secret_string`, the secret value can be stored in Terraform state. Only do this if state is encrypted, access-restricted, and this trade-off is accepted.

### IAM policy for application read access

```hcl
resource "aws_iam_policy" "read_app_db_secret" {
  name = "read-prod-myapp-db-secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.app_db.arn
      }
    ]
  })
}
```

Attach this policy to the application role only. Do not grant `secretsmanager:*` or `Resource = "*"`.

### Rotation

- Rotate the actual secret value in Secrets Manager (manually or with a rotation Lambda).
- Redeploy or restart applications only if they cache the secret.
- Prefer applications that can refresh secrets or retrieve them on startup.
- Validate that the old secret is no longer used before deleting it. Secrets Manager keeps previous versions (`AWSPREVIOUS`) to help with staged rollover.

---

## 7. Terraform with AWS SSM Parameter Store

SSM Parameter Store is enough for:

- Configuration values.
- Simple secrets (`SecureString` with KMS).
- Environment variables.
- Lower-complexity setups.
- Values that do not need advanced rotation workflows.

Standard parameters are free; Secrets Manager charges per secret. But Secrets Manager adds managed rotation, cross-account access, and secret-specific features. They are not identical: use Secrets Manager for application secrets and rotation, Parameter Store for simpler hierarchical configuration.

### SecureString parameter

```hcl
resource "aws_ssm_parameter" "app_token" {
  name  = "/prod/myapp/api_token"
  type  = "SecureString"
  value = var.api_token

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

> If Terraform manages the `value`, it can be stored in Terraform state. Prefer creating the parameter path and permissions in Terraform, and writing the actual value through a secure operational process (for example `aws ssm put-parameter` run by an operator or a controlled pipeline).

### IAM policy for parameter read access

```hcl
resource "aws_iam_policy" "read_app_parameters" {
  name = "read-prod-myapp-parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:eu-central-1:123456789012:parameter/prod/myapp/*"
      }
    ]
  })
}
```

The hierarchical path (`/prod/myapp/*`) makes least-privilege scoping straightforward. For `SecureString` parameters the role also needs `kms:Decrypt` on the KMS key used.

---

## 8. Terraform with HashiCorp Vault

HashiCorp Vault is a centralized secrets management service. Use cases:

- Centralized secret management across teams and platforms.
- Dynamic credentials (database users, cloud credentials generated on demand with a TTL).
- Kubernetes workloads (Kubernetes auth, Vault Agent injector, CSI provider).
- Multi-cloud or hybrid environments.
- Strong policy-based access control.

### Basic setup

```bash
export VAULT_ADDR="https://vault.example.com"
vault login
vault secrets enable -path=secret kv-v2
```

Write a secret:

```bash
vault kv put secret/prod/myapp/db username="app" password="change-me"
```

Read a secret:

```bash
vault kv get secret/prod/myapp/db
vault kv get -field=password secret/prod/myapp/db
```

### Policy

Note that KV v2 data is read at `secret/data/...`, not `secret/...`:

```hcl
path "secret/data/prod/myapp/db" {
  capabilities = ["read"]
}
```

### Terraform provider

```hcl
provider "vault" {
  address = var.vault_addr
}

data "vault_kv_secret_v2" "app_db" {
  mount = "secret"
  name  = "prod/myapp/db"
}
```

> Reading Vault secrets through Terraform can still put secret values into Terraform state if those values are used in managed resources or outputs. Data source results are recorded in state. Prefer runtime access from the application where possible.

### Better pattern

Use Terraform for Vault configuration, not secret values:

- Terraform creates Vault policies, auth roles, Kubernetes auth bindings, and app permissions (`vault_policy`, `vault_kubernetes_auth_backend_role`, mounts).
- The application retrieves secrets at runtime using Vault Agent, the Vault CSI provider, a Vault SDK, or an approved platform mechanism.

This keeps secret values out of Terraform state entirely, while access control stays declarative and reviewable.

---

## 9. CI/CD Usage Patterns

### Ansible Vault in CI/CD

- Store the vault password in CI/CD secret storage (GitHub Actions secrets, GitLab CI variables, etc.).
- Write it to a temporary file during the pipeline.
- Run the playbook with `--vault-password-file`.
- Delete the temporary file after the job.
- Ensure logs do not print secret values (`no_log: true`, no debug tasks on secrets).

```bash
printf "%s" "$ANSIBLE_VAULT_PASSWORD" > .vault_pass
chmod 600 .vault_pass
ansible-playbook -i inventory.ini playbook.yml --vault-password-file .vault_pass
rm -f .vault_pass
```

### Terraform in CI/CD

- Use OIDC federation to AWS where possible (short-lived credentials per job).
- Do not store long-lived AWS keys in CI/CD unless unavoidable.
- Run `terraform plan` on pull requests.
- Run `terraform apply` only after review/approval on merge.
- Protect the state backend: the CI role needs state access, nothing broader than required.
- Avoid printing plan files that may contain secrets; do not upload raw plan files as public artifacts.

### Secrets Manager / Vault in CI/CD

- CI/CD can write or rotate secrets if it has explicit, scoped permission for that.
- Application runtime should usually read secrets directly; CI/CD should not be a secret relay.
- CI/CD must not dump secret values into logs. Masking helps but is not a guarantee — do not rely on it.

---

## 10. Rotation vs Rekey vs Redeploy

| Action | What changes | Example | Requires app redeploy? |
|---|---|---|---|
| Ansible Vault rekey | Vault file encryption password | `ansible-vault rekey` | No, unless secret value changed |
| Secret rotation | Actual secret value | DB password changed | Usually yes, unless app refreshes secrets |
| Terraform state migration | State location or backend | local state to S3 backend | No, but requires careful migration |
| IAM credential rotation | Access key or role credentials | replace static key | Maybe, depending on usage |
| Vault policy update | Access rules | add/remove read access | No, unless app needs new token/session |

The distinction in one sentence each:

- **Rekey** protects the encrypted file. The secret inside is unchanged.
- **Rotation** changes the actual credential. Anything using the old value breaks or must switch.
- **Redeploy/restart** makes applications pick up changed secrets if they do not refresh dynamically.

A complete rotation is: change the value in the secret store, make consumers pick it up, verify the old value is no longer used, then invalidate the old value.

---

## 11. Common Mistakes

- Committing `.vault_pass` to Git. The vault files are then effectively plaintext.
- Thinking Ansible Vault is the same as HashiCorp Vault. One encrypts files in a repo; the other is a secrets management service.
- Thinking Terraform `sensitive = true` means the value is not in state. It only masks CLI output.
- Using Terraform to manage raw secret values without protecting state (no encryption, broad access).
- Printing secrets in Ansible debug output or forgetting `no_log: true` on tasks that handle them.
- Passing secrets through CLI arguments and leaking them into shell history or process lists.
- Giving CI/CD admin permissions to all secrets instead of scoped read/write on specific paths.
- Not separating dev/staging/prod secrets — one leaked dev credential should never open prod.
- Not rotating secrets after employee/vendor access changes.
- Not testing whether apps actually picked up rotated secrets, leading to outages hours later when connections recycle.

---

## 12. Recommended Decision Matrix

| Use case | Recommended tool | Reason |
|---|---|---|
| Small Ansible-only repo secrets | Ansible Vault | Simple and Git-friendly |
| AWS application runtime secrets | AWS Secrets Manager | Native AWS integration and rotation support |
| Simple AWS config/secrets | SSM Parameter Store | Lower complexity, hierarchical paths |
| Multi-cloud centralized secrets | HashiCorp Vault | Strong policy and auth model |
| Terraform module validation | Terraform variables + validation | Not a secret store |
| CI/CD cloud access | OIDC + IAM role | Avoid long-lived keys |

---

## 13. Final Interview-Ready Summary

> For Ansible, I use Ansible Vault to encrypt Ansible-specific secret files, keep normal variables separate from vaulted variables, and use `ansible-vault rekey` when I need to rotate the vault file password. Rekey is not the same as rotating the actual application secret.
>
> For Terraform, I avoid storing raw secret values where possible because sensitive values can still end up in state or plan files. Terraform should usually create secret containers, IAM policies, references, and wiring. Applications should read secrets at runtime from AWS Secrets Manager, SSM Parameter Store, or HashiCorp Vault. If Terraform must manage secret values, then state encryption, restricted state access, CI/CD log hygiene, and rotation procedures are mandatory.

---

## Appendix: Command Cheat Sheets

### Ansible Vault Commands

```bash
ansible-vault encrypt file.yml
ansible-vault decrypt file.yml
ansible-vault view file.yml
ansible-vault edit file.yml
ansible-vault rekey file.yml
ansible-vault encrypt_string 'value' --name 'variable_name'
```

### Vault KV Commands

```bash
vault secrets enable -path=secret kv-v2
vault kv put secret/prod/myapp/db username="app" password="change-me"
vault kv get secret/prod/myapp/db
vault kv get -field=password secret/prod/myapp/db
vault kv metadata get secret/prod/myapp/db
```

### Terraform Commands

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan
terraform apply
terraform state list
terraform state show <resource>
```

---

## References

- [Ansible Vault documentation](https://docs.ansible.com/projects/ansible/latest/vault_guide/index.html)
- [Terraform: manage sensitive data](https://developer.hashicorp.com/terraform/language/manage-sensitive-data)
- [AWS prescriptive guidance: Secrets Manager with Terraform](https://docs.aws.amazon.com/prescriptive-guidance/latest/secure-sensitive-data-secrets-manager-terraform/)
- [AWS SSM Parameter Store documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [HashiCorp Vault KV documentation](https://developer.hashicorp.com/vault/docs/secrets/kv)
