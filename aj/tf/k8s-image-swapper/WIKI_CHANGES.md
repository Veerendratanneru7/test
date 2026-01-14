# k8s-image-swapper - Wiki of Changes

Ticket: <ADD_TICKET_ID>
Repo path: `tf/k8s-image-swapper`
Owner: <ADD_OWNER>
Last updated: <ADD_DATE>

## Overview
- Goal: Deploy k8s-image-swapper as a Terraform-managed Helm release with safe, phased rollout controls.
- Current status: Phase 1 dry-run enabled; Phase 2 prepared with allowlist-based mutations.
- Intended outcome: route selected images to ECR while keeping protected namespaces untouched and minimizing risk during rollout.

## Scope
- New Terraform module under `tf/k8s-image-swapper` to manage Helm release, IAM role, and ECR permissions.
- Safe rollout controls for dry-run and targeted mutation phases.
- Filters to exclude protected namespaces and optionally allowlist target namespaces.
- Rewrite rules to map specific source registries to the target ECR path.

## Key Changes
### Helm deployment (Terraform-managed)
- Added `helm_release` for `k8s-image-swapper` with configurable chart version and namespace.
- Generated Helm values via Terraform locals for:
  - dry-run control (`config.dryRun`)
  - logging (`logLevel=debug`, `logFormat=console`)
  - swap/copy policy (`config.imageSwapPolicy`, `config.imageCopyPolicy`)
  - filters and AWS target settings
  - rewrite rules for specific source images
- Namespace and release name default to `kube-system` and `k8s-image-swapper` for consistent service account naming.

### IAM + ECR permissions
- Created OIDC-based IAM role for the webhook service account.
- Attached ECR permissions needed for batch get, upload, and repository management.
- Scope: permissions are limited to ECR resources in the target account/region.

### Namespace filtering + phased rollout
- Protected namespaces are excluded by default.
- Target namespaces are allowlisted for limited mutation phase.
- Dry-run and mutation toggles exposed as variables.
- Filters also include a guard to only act on images that already reference ECR domains.

## Architecture / Flow
1) Admission webhook receives pod create/update requests.
2) Filters evaluate namespace exclusions and allowlist conditions.
3) In dry-run, the webhook logs decisions without applying changes.
4) When mutations are enabled, matching image references are rewritten to ECR.
5) If required by policy, missing images are copied to ECR before rewrite.

## Files Added / Updated
- `tf/k8s-image-swapper/main.tf`: Helm values, filters, rewrite rules, IAM role and policy.
- `tf/k8s-image-swapper/variables.tf`: Phase controls, namespace filters, image policies.
- `tf/k8s-image-swapper/providers.tf`: Providers and EKS auth wiring.
- `tf/k8s-image-swapper/backend.tf`: Remote state config.
- `tf/k8s-image-swapper/outputs.tf`: IAM role ARN output.
- `tf/k8s-image-swapper/fnd-ci/ghe/ghe-sandbox.tfvars`: Phase 1 dry-run config.

## Rollout Phases
### Phase 1 - Dry Run (current)
- `dry_run = true`
- `enable_mutations = false`
- `target_namespaces = []`
Expected behavior:
- Webhook logs potential mutations only.
- No workloads mutated.
- Use logs to validate filter logic and detect unexpected matches.

### Phase 2 - Limited Mutations (ready)
- `dry_run = false`
- `enable_mutations = true`
- `target_namespaces = ["<noncritical-ns-1>", "<noncritical-ns-2>"]`
Expected behavior:
- Only allowlisted namespaces are mutated.
- Image references are rewritten to ECR for matching rules.
- Protected namespaces are never mutated.

## Configuration Details
### Defaults (safe)
- `protected_namespaces`: `kube-system`, `kube-public`, `kube-node-lease`
- `image_swap_policy`: `exists`
- `image_copy_policy`: `delayed`

### Variable -> Helm value mapping
- `dry_run` -> `config.dryRun`
- `enable_mutations` -> `imageSwapper.enabled`
- `image_swap_policy` -> `config.imageSwapPolicy`
- `image_copy_policy` -> `config.imageCopyPolicy`
- `protected_namespaces`, `target_namespaces` -> `config.source.filters` (JMESPath rules)
- `aws_account_id`, `region` -> `config.target.aws`

### Filter logic (JMESPath)
- Exclude protected namespaces: `obj.metadata.namespace == '<protected-ns>'`
- Optional allowlist: only mutate when namespace is in `target_namespaces`.
- ECR guard: only act on images containing `.dkr.ecr.` and `.amazonaws.com`.

### Rewrite Rules (current)
- `v-gha.artifactory.aws.venmo.biz/docker` -> `<account>.dkr.ecr.<region>.amazonaws.com/sre/prod/docker/gha/node`
- `v-gha.artifactory.aws.venmo.biz/v-actions-runner` -> `<account>.dkr.ecr.<region>.amazonaws.com/sre/prod/docker/gha/node`
- `v-gha.artifactory.aws.venmo.biz/v-gha-husky` -> `<account>.dkr.ecr.<region>.amazonaws.com/sre/prod/docker/gha/node`
- `v-gha.artifactory.aws.venmo.biz/gha-runner-scale-set-controller` -> `<account>.dkr.ecr.<region>.amazonaws.com/sre/prod/docker/gha/node`

### IAM policy details (ECR actions)
- Read: `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, `ecr:DescribeRepositories`
- Write: `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`
- Repo management: `ecr:CreateRepository`

## Validation Checklist
### Phase 1
- Webhook pod running in `kube-system`.
- Logs show evaluated mutations only (no changes applied).
- Protected namespaces not matched.
- Confirm no new images are pulled from ECR as a result of mutations.

### Phase 2
- Pods in allowlisted namespaces show rewritten images to ECR.
- No ImagePull errors in mutated workloads.
- Logs show copy/swap activity per policy.
- Validate that images exist in ECR for rewritten references.

## Rollback
- Set `enable_mutations = false` and `dry_run = true`.
- Optionally remove target namespaces from allowlist.
- Apply Terraform to return to observe-only mode.

## Known Assumptions
- The EKS cluster OIDC provider is configured and reachable.
- Target ECR registry permissions are granted via the IAM role.
- Rewrite rules reflect the correct source images for this environment.

## Open Items / Next Steps
- Confirm final ticket ID and owner for this page.
- Decide allowlisted namespaces for Phase 2.
- Promote from dry-run after log validation window.
- Document the exact verification window length and log review owner.
