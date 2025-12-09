# k8s-image-swapper —  Summary

---

## Quick summary (what I did)

- Implemented a focused Terraform module to deploy `k8s-image-swapper` into EKS.
- Added phased rollout controls so we can observe behavior before enabling mutations.
- Configured IAM and ECR permissions for the webhook pod (OIDC-based role assumption).

---

## What the code does:

- Installs the `k8s-image-swapper` Helm chart (default namespace: `kube-system`).
- Creates an IAM role that the webhook pod assumes via the cluster OIDC provider so it can interact with ECR (copy/pull images).
- Generates JMESPath-based filters from Terraform variables to exclude protected namespaces and optionally allowlist target namespaces.
- Exposes phase-control variables so we can switch between dry-run (observe) and mutation (act) modes safely.

---

## Files changed / added (one-line descriptions)

- `variables.tf` — Added phase-control and policy variables: `dry_run`, `enable_mutations`, `protected_namespaces`, `target_namespaces`, `image_swap_policy`, `image_copy_policy`.
- `main.tf` — Dynamic Helm values generation (JMESPath filters), Helm release resource, IAM role and permissions for ECR operations.
- `backend.tf`, `providers.tf`, `outputs.tf` — Terraform state backend, providers, and outputs kept minimal and consistent.
- `fnd-ci/ghe/ghe-sandbox.tfvars` —  `tfvars` configured for Phase 1 (dry-run).

---

## Phase definitions (how to explain in the meeting)

### Phase 1 — Dry-Run (current)

- What it does: The webhook evaluates and logs the mutations it would perform but does not change any manifests or images.
- Terraform flags used:
  - `dry_run = true`
  - `enable_mutations = false`
  - `target_namespaces = []` (empty by default)
- Purpose: validate filter logic and ensure we do not unintentionally affect system or other workloads.
- Acceptance: webhook pod is running; logs show expected mutation evaluations; no changes in cluster workloads.

### Phase 2 — Limited Mutations (next)

- What it does: The webhook rewrites image references to the target ECR for workloads in the allowlisted namespaces.
- Terraform flags used:
  - `dry_run = false`
  - `enable_mutations = true`
  - `target_namespaces = ["noncritical-ns-1", "noncritical-ns-2"]`
- Purpose: confirm image rewrite and copy behavior in a controlled, low-risk subset of namespaces.
- Acceptance: rewritten image references in the target namespaces pull from ECR successfully; protected namespaces remain untouched; no unexpected ImagePull failures.

---

## Safety controls (why we’re safe)

- **Protected namespaces** (defaults): `kube-system`, `kube-public`, `kube-node-lease`. These are never mutated.
- **Allowlist (`target_namespaces`)**: For Phase 2, mutations only apply to explicitly listed namespaces.
- **Image policies**: `image_swap_policy` and `image_copy_policy` default to conservative options (only swap if image already exists in ECR; delayed copy) to avoid causing ImagePull failures.

---

## Validation checklist (what to look for)

Phase 1 (dry-run):
- Webhook pod is running in `kube-system`.
- Logs show mutation evaluations but no applied rewrites.
- Protected namespaces show no mutation matches.

Phase 2 (limited mutations):
- Pods in target namespaces have image references rewritten to ECR (on new pod creation).
- Pods start without ImagePull errors.
- Logs show copy or swap activity per `image_copy_policy`.

---