# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Terraform for Skilli's production AWS platform infrastructure (VPC, EKS, shared services, networking), built incrementally as a three-tier, highly-available architecture on EKS in `ap-south-1`. So far: VPC networking (public/private/database subnets across 2 AZs, per-AZ NAT gateways) and EKS IAM/KMS foundations (cluster + node IAM roles, Secrets encryption key).

## Commands

Run from `envs/prod/` (each environment is its own Terraform working directory):

```bash
cd envs/prod
terraform init -input=false
terraform fmt -check -recursive   # run from repo root to also cover modules/
terraform validate
terraform plan -input=false -var-file=prod.tfvars
terraform apply -input=false -var-file=prod.tfvars
```

Always pass `-var-file=prod.tfvars` (or another `*.tfvars`) since `variables.tf` declares `project_name`, `environment`, and `aws_region` with no defaults.

## Architecture

- **Layout**: `modules/<name>/` holds reusable resource groups (currently `network`, `eks`); `envs/<environment>/` is a thin root module per environment that calls those modules with environment-specific sizing/tfvars. Only `envs/prod/` exists today — adding another environment (e.g. `staging`) means a new `envs/<env>/` directory with its own `backend.tf` (distinct state key) and tfvars, reusing the same modules.
- **Modules**:
  - `modules/network` — VPC, public/private/database subnets (2 AZs), IGW, one NAT Gateway per AZ, per-tier route tables. Subnets are pre-tagged for EKS auto-discovery (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`, `kubernetes.io/cluster/<cluster_name>`).
  - `modules/eks` — EKS cluster & node IAM roles, and a KMS key for Kubernetes Secrets envelope encryption. Will grow to include the cluster, node groups, and OIDC provider in later phases.
- **State**: remote S3 backend, one state file per environment — bucket `skilli-prod-627807502978-tf-state`, key `envs/<environment>/terraform.tfstate` (prod: `envs/prod/terraform.tfstate`), region `ap-south-1`, native S3 locking (`use_lockfile = true`, no DynamoDB table). (Prior to the modules/envs restructure, prod state lived at `infra/terraform.tfstate`; that key is left in S3 unused as a historical artifact.)
- **Provider**: `hashicorp/aws ~> 6.0`, Terraform `~> 1.12` (`envs/<env>/versions.tf`). Region comes from `var.aws_region`; `envs/<env>/provider.tf` applies `local.common_tags` to all resources (including module-created ones) via `default_tags`.
- **Naming/tagging convention**: each `envs/<env>/locals.tf` derives `local.name_prefix = "${var.project_name}-${var.environment}"`, `local.cluster_name = "${local.name_prefix}-eks"`, and `local.common_tags` (Project, Environment, ManagedBy=Terraform, Repository). These are passed into modules as inputs — modules take `name_prefix`/`cluster_name` as variables rather than hardcoding.
- **tfvars**: `envs/<env>/prod.tfvars` (etc.) is committed and is the file CI uses. `envs/prod/terraform.tfvars` is gitignored and exists only locally as a dev-time mirror (auto-loaded by Terraform without `-var-file` when run from `envs/prod/`) — don't assume it's present in a fresh checkout or in CI.

## CI/CD (`.github/workflows/terraform.yml`)

- Triggers on push to `main` and on pull requests.
- `terraform-plan` job runs on every push/PR: `fmt -check -recursive` (repo root, covers `modules/` + `envs/`), then `init`/`validate`/`plan -var-file=prod.tfvars` from `working-directory: envs/prod`, authenticated via OIDC as `skilli-prod-github-infra-plan-role`.
- `terraform-apply` job runs only on push to `main` (after plan succeeds): `init`/`apply -auto-approve -var-file=prod.tfvars` from `working-directory: envs/prod`, authenticated as `skilli-prod-github-infra-role`. **No manual approval gate** — merges to `main` apply automatically.
- Both jobs assume roles via `aws-actions/configure-aws-credentials` OIDC (`id-token: write` permission) — no long-lived AWS credentials are stored.
- `concurrency.group: terraform-infra` with `cancel-in-progress: false` serializes runs so concurrent plans/applies against the same state don't race. If a second environment is added, this concurrency group likely needs to become per-environment (e.g. `terraform-infra-${{ matrix.env }}`) so envs don't serialize against each other unnecessarily.
