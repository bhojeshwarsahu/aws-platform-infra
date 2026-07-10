# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Terraform root module for Skilli's production AWS platform infrastructure (VPC, EKS, shared services, networking). The repo is currently at bootstrap stage: only backend/provider/variable scaffolding exists (`backend.tf`, `provider.tf`, `versions.tf`, `variables.tf`, `locals.tf`) — no actual infrastructure resources have been added yet.

## Commands

```bash
terraform init -input=false
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -var-file=prod.tfvars
terraform apply -input=false -var-file=prod.tfvars
```

There are no modules, tests, or a Makefile — this is a flat, single root module. Always pass `-var-file=prod.tfvars` (or another `*.tfvars`) since `variables.tf` declares `project_name`, `environment`, and `aws_region` with no defaults.

## Architecture

- **State**: remote S3 backend (`backend.tf`) — bucket `skilli-prod-627807502978-tf-state`, key `infra/terraform.tfstate`, region `ap-south-1`, native S3 locking (`use_lockfile = true`, no DynamoDB table).
- **Provider**: `hashicorp/aws ~> 6.0`, Terraform `~> 1.12` (`versions.tf`). Region comes from `var.aws_region`; `provider.tf` applies `local.common_tags` to all resources via `default_tags`.
- **Naming/tagging convention**: `locals.tf` derives `local.name_prefix = "${var.project_name}-${var.environment}"` and `local.common_tags` (Project, Environment, ManagedBy=Terraform, Repository). New resources should reuse `local.name_prefix` for naming rather than hardcoding.
- **tfvars**: `prod.tfvars` is committed and is the file CI uses. `terraform.tfvars` is gitignored and exists only locally as a dev-time mirror of `prod.tfvars` (auto-loaded by Terraform without `-var-file`) — don't assume it's present in a fresh checkout or in CI.

## CI/CD (`.github/workflows/terraform.yml`)

- Triggers on push to `main` and on pull requests.
- `terraform-plan` job runs on every push/PR: `fmt -check`, `init`, `validate`, `plan -var-file=prod.tfvars`, authenticated via OIDC as `skilli-prod-github-infra-plan-role`.
- `terraform-apply` job runs only on push to `main` (after plan succeeds): `apply -auto-approve -var-file=prod.tfvars`, authenticated as `skilli-prod-github-infra-role`.
- Both jobs assume roles via `aws-actions/configure-aws-credentials` OIDC (`id-token: write` permission) — no long-lived AWS credentials are stored.
- `concurrency.group: terraform-infra` with `cancel-in-progress: false` serializes runs so concurrent plans/applies against the same state don't race.
