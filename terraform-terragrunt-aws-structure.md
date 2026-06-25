# Terraform and Terragrunt AWS Infrastructure Structure

This document outlines the recommended structure and operating model for managing AWS infrastructure using Terraform and Terragrunt. The goal is to provide a standardized, safe, and scalable approach to infrastructure as code (IaC) that supports multiple environments (dev, qa, stage, prod) while emphasizing reusability and operational safety.

## Disclaimer

This document describes a recommended Terraform and Terragrunt structure. It is not a complete production implementation.

The examples are intentionally simplified and should be adapted before being used in real AWS accounts.

Do not run apply or destroy commands against production infrastructure without reviewing the plan, confirming the target AWS account and region, and having an approved rollback plan.

## Tooling note

Command syntax can differ between Terraform, OpenTofu, and Terragrunt versions.

This document uses the newer Terragrunt command style:

```bash
terragrunt run plan
terragrunt run apply
terragrunt run --all plan
terragrunt run --all apply
```

Verify the exact syntax against the Terragrunt version used in your environment.

Broad commands such as `terragrunt run --all apply` and especially `terragrunt run --all destroy` should be used carefully. They can affect multiple infrastructure units and should not be used casually against shared or production environments.

## Repository Purpose

This repository defines the target state of the AWS infrastructure. It is designed around a three-layer model that separates generic resource definitions from service-level compositions and environment-specific deployments. This structure prevents duplication, ensures consistency across environments, and provides clear boundaries for changes.

## Recommended Repository Structure

The target state repository structure is as follows:

```text
.
├── README.md
├── docs/
│   └── terraform-terragrunt-aws-structure.md
│
├── modules/
│   ├── s3-bucket/
│   ├── kms-key/
│   ├── ec2-instance/
│   ├── ebs-volume/
│   ├── iam-role/
│   ├── security-group/
│   └── cloudwatch-alarm/
│
├── templates/
│   ├── jenkins-controller/
│   ├── backup-storage/
│   ├── app-server/
│   └── monitoring-baseline/
│
├── live/
│   ├── root.hcl
│   ├── common.hcl
│   ├── dev/
│   ├── qa/
│   ├── stage/
│   └── prod/
│
└── scripts/
    ├── validate.sh
    ├── plan-env.sh
    └── plan-unit.sh
```

## Three-Layer Architecture

### Layer 1: Terraform Modules

Terraform modules are reusable, environment-agnostic building blocks. 

Examples:

```text
modules/
├── s3-bucket/
├── kms-key/
├── ec2-instance/
├── ebs-volume/
├── iam-role/
├── security-group/
└── cloudwatch-alarm/
```

A module should answer:
```text
How do we create this type of AWS resource in a standardized way?
```

Modules should enforce security baselines (e.g., encryption by default) and tagging standards. A module must not know whether it is deployed in dev, qa, stage, or prod. All environment-specific behaviors must be driven through module inputs.

#### Example Module Structure

```text
modules/s3-bucket/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

- `main.tf`: Contains the actual resource definitions.
- `variables.tf`: Defines the inputs the module accepts.
- `outputs.tf`: Exposes values useful for dependencies.
- `versions.tf`: Defines Terraform version and provider constraints.
- `README.md`: Documents usage instructions.

#### Example Terraform Module Snippet

**`main.tf`**
```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.name

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}
```

**`variables.tf`**
```hcl
variable "name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
```

**`outputs.tf`**
```hcl
output "bucket_id" {
  description = "S3 bucket ID."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}
```

### Layer 2: Service Templates / Compositions

Templates or compositions combine several lower-level modules into a meaningful service or platform component. These are higher-level Terraform root modules that represent a deployable unit rather than copy-paste examples.

Examples:

```text
templates/
├── jenkins-controller/
├── backup-storage/
├── app-server/
└── monitoring-baseline/
```

#### Example Service Composition

A `jenkins-controller` composition may call multiple modules internally:

```hcl
module "kms" {
  source = "../../modules/kms-key"

  name = var.kms_key_name
}

module "backup_bucket" {
  source = "../../modules/s3-bucket"

  name       = var.backup_bucket_name
  kms_key_id = module.kms.key_id
}

module "controller" {
  source = "../../modules/ec2-instance"

  name               = var.instance_name
  instance_type      = var.instance_type
  iam_role_name      = var.iam_role_name
  security_group_ids = var.security_group_ids
}

module "data_volume" {
  source = "../../modules/ebs-volume"

  name       = var.ebs_volume_name
  size       = var.ebs_volume_size
  encrypted  = true
  kms_key_id = module.kms.key_id
}
```

The composition defines *what* resources are required to run a specific service, whereas the Terragrunt layer will define *where* and *how* it is deployed.

### Layer 3: Terragrunt Live Layer

Terragrunt manages the real deployments and instantiates templates with environment-specific values.

Example:

```text
live/
├── root.hcl
├── common.hcl
├── dev/
│   ├── env.hcl
│   └── eu-west-1/
│       ├── region.hcl
│       ├── network/
│       │   └── vpc/
│       │       └── terragrunt.hcl
│       ├── platform/
│       │   └── jenkins-controller/
│       │       └── terragrunt.hcl
│       └── storage/
│           └── artifact-bucket/
│               └── terragrunt.hcl
├── qa/
├── stage/
└── prod/
```

The live layer should answer:
```text
Which infrastructure should exist in this environment, account, and region?
```

## Remote State and Locking

Terraform state should be remote, not local. State must be encrypted, and access to state should be strictly restricted. Each Terragrunt unit should have its own separate state key to minimize blast radius.

State files can contain sensitive values, so backend credentials must never be hardcoded.

Historically, many Terraform AWS setups used S3 for state storage and DynamoDB for locking.

Newer Terraform versions also support S3-native lockfiles through `use_lockfile = true`.

If DynamoDB locking is shown as an example below, note that it is a historical/common pattern and teams should verify the current backend locking recommendation for their specific Terraform version.

### Example Terragrunt Root Configuration

```hcl
# live/root.hcl

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "company-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "company-terraform-locks"
  }
}

inputs = {
  environment = local.env.locals.environment
  region      = local.region.locals.region
  common_tags = local.common.locals.common_tags
}
```

- Remote state is stored in an S3 bucket with encryption enabled.
- State locking is handled through a DynamoDB table.
- Each Terragrunt unit gets an isolated state file using `path_relative_to_include()`, minimizing the blast radius of any operation.

## Environment configuration

Common variables for an environment or region are placed in hierarchical configuration files.

### Example Environment File

```hcl
# live/dev/env.hcl

locals {
  environment = "dev"

  account_id = "111111111111"

  common_tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "platform"
  }
}
```

### Example Region File

```hcl
# live/dev/eu-west-1/region.hcl

locals {
  region = "eu-west-1"
}
```

### Example Terragrunt Service Deployment

```hcl
# live/dev/eu-west-1/platform/jenkins-controller/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
  source = "../../../../../templates/jenkins-controller"
}

inputs = {
  name = "jenkins-${local.env.locals.environment}"

  instance_type   = "t3.medium"
  ebs_volume_size = 100

  backup_bucket_name = "jenkins-backups-${local.env.locals.environment}"
  kms_key_name       = "jenkins-kms-${local.env.locals.environment}"

  tags = local.env.locals.common_tags
}
```

## Dependency Handling

Terragrunt allows passing outputs from one deployment to another natively, eliminating the need to hardcode ARNs or IDs.

Values such as VPC IDs, subnet IDs, security group IDs, and KMS ARNs should never be copied manually between folders.

**Bad Example:**
```hcl
vpc_id = "vpc-123456"
```

**Good Example:**
```hcl
dependency "vpc" {
  config_path = "../../network/vpc"
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
}
```

## Deployment Commands

### Running Plan/Apply on a Single Unit

```bash
cd live/dev/eu-west-1/platform/jenkins-controller
terragrunt run plan
terragrunt run apply
```

### Running Plan/Apply on a Full Environment

```bash
cd live/dev/eu-west-1
terragrunt run --all plan
```

```bash
cd live/dev/eu-west-1
terragrunt run --all apply
```

Full-environment apply operations (`run --all apply`) should be used carefully, generally restricted to controlled CI/CD pipelines or initial bootstrapping scenarios.

**Warning:**
Strictly avoid casual use of `terragrunt run --all destroy`.

## Branching Strategy

Environments should not be managed through long-lived branches.

**Avoid:**
```text
dev branch
qa branch
stage branch
prod branch
```

**Recommended:**
```text
main branch = source of truth
feature branches = short-lived changes
live/dev = dev environment
live/qa = qa environment
live/stage = stage environment
live/prod = prod environment
```

**Rule:**
Branches are for code review. Folders are for environments.

## PR-Based Workflow

All changes should follow an automated and reviewed pull request workflow:

```text
feature branch
  ↓
pull request
  ↓
format check
  ↓
validate
  ↓
lint/security scan
  ↓
terragrunt plan
  ↓
review plan output
  ↓
merge
  ↓
apply to dev
  ↓
promote to qa
  ↓
promote to stage
  ↓
manual approval
  ↓
apply to prod
```

Pull Requests should explicitly include:
* What changed
* Which environments are affected
* Plan output summary
* Whether resource replacement or deletion is expected
* A rollback plan
* Assessed risk level
* Whether module inputs or outputs changed

## Promotion Strategy

### Simple Folder-Based Promotion

A change is first applied to `live/dev/`. Once validated, the change is merged and eventually replicated into the configurations for `live/qa/`, `live/stage/`, and `live/prod/`. This strategy is simple and highly suitable for smaller teams or a portfolio repository.

### Versioned Module Promotion

Mature setups often use Git tags to strictly version modules and templates.

Example:
```hcl
terraform {
  source = "git::ssh://git@github.com/company/terraform-aws-platform.git//templates/jenkins-controller?ref=v1.4.0"
}
```

Version progression over time:
```text
dev   -> v1.5.0
qa    -> v1.5.0
stage -> v1.4.0
prod  -> v1.4.0
```

After successful staging verification:
```text
stage -> v1.5.0
prod  -> v1.5.0
```

*Note: For the scope of this repository, local source paths are acceptable, while real-world enterprise deployments often rely on versioned modules.*

## Backward Compatibility and Safe Refactoring

A module or template is considered backward-compatible when existing environments can upgrade to the new version without changing their current inputs and without triggering unexpected resource replacement or deletion.

### Safe Changes
* Adding a new optional variable with a default
* Adding a new output
* Adding tags that do not force replacement
* Adding a feature behind an `enabled = false` flag
* Improving documentation
* Adding examples
* Adding validation to new variables

### Risky Changes
* Changing default values
* Renaming variables
* Removing variables
* Changing variable types
* Renaming outputs
* Changing resource names
* Changing `for_each` keys
* Changing `count` logic
* Changing naming conventions
* Changing provider versions
* Changing lifecycle blocks
* Changing backend state keys

### Breaking Changes
* Removing an input used by live environments
* Removing an output consumed by another Terragrunt unit
* Renaming a Terraform resource without a `moved` block
* Changing resource addressing
* Changing state location
* Forcing replacement of production resources without explicit migration paths
* Changing module behavior without versioning

## Refactoring safety note

Terraform resource addresses are part of the state contract.

Renaming resources, moving resources into modules, changing module paths, changing `for_each` keys, or changing `count` logic can cause Terraform to plan resource deletion and recreation.

Before applying a refactor:

- review the plan carefully
- check for unexpected destroy or replace actions
- use `moved` blocks when supported
- test the change in a lower environment first
- document any required migration steps

Example:

```hcl
moved {
  from = aws_instance.jenkins
  to   = aws_instance.controller
}
```

A refactor should not be treated as a cosmetic change when Terraform state is involved.

### Variable Rules

Adding a required variable to an existing module is a breaking change because it forces all consumers to update immediately.

**Bad:**
```hcl
variable "backup_enabled" {
  type = bool
}
```

**Better:**
```hcl
variable "backup_enabled" {
  description = "Whether backups should be enabled."
  type        = bool
  default     = false
}
```

### Output Rules

Outputs define the module contract and API.

**Bad:**
```hcl
output "id" {
  value = aws_s3_bucket.this.id
}
```

**Better:**
```hcl
output "bucket_id" {
  description = "S3 bucket ID."
  value       = aws_s3_bucket.this.id
}
```

If an output must be renamed:
1. Add the new output.
2. Keep the old output temporarily.
3. Mark the old output as deprecated.
4. Update all downstream consumers.
5. Remove the old output in the next major version release.

## Backend and state sensitivity

Terraform state can contain sensitive values, depending on the resources and providers used.

Backend credentials should not be hardcoded in Terraform or Terragrunt configuration.

Avoid committing:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- local plan files
- backend config files containing credentials
- `.tfvars` files containing secrets

Remote state should have encryption, access control, and locking enabled.

## Secrets Handling

Never commit plain text secrets to the repository.

**Avoid Committing:**
* Passwords
* Private keys
* API tokens
* Cloud credentials
* `kubeconfig` files
* Jenkins admin passwords
* Terraform state files
* `.tfvars` files containing secrets

**Recommended Secret Management:**
* AWS Secrets Manager
* AWS Systems Manager Parameter Store
* HashiCorp Vault
* CI/CD secret storage

## Environment Differences

Differences between environments should be driven by Terragrunt input values, never by duplicating module logic.

**Example Dev Configuration:**
```hcl
inputs = {
  instance_type   = "t3.small"
  ebs_volume_size = 50
}
```

**Example Prod Configuration:**
```hcl
inputs = {
  instance_type   = "m6i.large"
  ebs_volume_size = 500
}
```

Both environments consume the exact same template, differing only by configuration values.

## Standard Checks

Before opening a pull request, run local formatting and validation checks.

Formatting:
```bash
terraform fmt -recursive
terragrunt hcl fmt
```

Validation:
```bash
terragrunt run validate
terragrunt run plan
```

For full environment checks:
```bash
cd live/dev/eu-west-1
terragrunt run --all plan
```

Recommended additional checks in CI pipelines:
```bash
tflint
checkov
tfsec
```

## What to Avoid

The team should actively avoid the following anti-patterns:
* Managing environments through long-lived branches
* Hardcoding environment-specific values inside modules
* Committing secrets
* Committing `.terraform/` directories
* Committing Terraform state files
* Using `run --all apply` blindly
* Making production changes without PR review
* Changing module inputs without verifying all downstream consumers
* Renaming resources without proper migration blocks
* Upgrading to the latest provider versions without strict constraints
* Manually changing Terraform-managed resources in the AWS Console
* Changing state keys casually
* Changing `for_each` keys casually
* Modifying naming conventions for existing resources

## Production safety checklist

Before applying to production:

- [ ] The pull request has been reviewed
- [ ] The plan has been reviewed
- [ ] The target AWS account is confirmed
- [ ] The target AWS region is confirmed
- [ ] No unexpected delete actions are present
- [ ] No unexpected replacement actions are present
- [ ] State changes are understood
- [ ] Module input changes are backward-compatible
- [ ] Module output changes do not break dependencies
- [ ] Provider version changes are reviewed
- [ ] Rollback plan exists
- [ ] Manual approval has been granted
