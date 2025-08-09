# Sprint 0: Remote Backend Setup

## Why Remote State is Non-Negotiable
Problems with local state in teams:
1. **Collaboration risk** — Each person’s state can differ → drift & overwrites.
2. **State corruption risk** — If your laptop dies, the state is gone.
3. **No locking** — Two people running `terraform apply` at the same time → race conditions.

---

## Why Create the Backend with AWS CLI (Not Terraform Itself)

**Problem:**
- **Bootstrap chicken-and-egg** — You can’t store state in S3 until the bucket exists.
- If you create it with Terraform, the first run must use local backend, then reconfigure backend, then migrate state → 2-step process.

**Solution:**
- Create the S3 bucket + DynamoDB table *manually* with AWS CLI before running Terraform.
- Point Terraform’s `backend "s3"` to that bucket in `backend.tf`.

---

## Benefits of Manual Bootstrapping
1. **Bootstrap safety** — First run always succeeds.
2. **Independence from Terraform state** — Backend infra can’t be destroyed by `terraform destroy`.
3. **Rescue-friendly** — Even if Terraform state is lost, backend infra survives for recovery.

---

## Why S3 + DynamoDB?

| Component | Purpose |
|-----------|---------|
| **S3** | Durable state storage + versioning |
| **DynamoDB** | State locking to prevent concurrent changes |
| **Encryption** | Meets GDPR/CCPA compliance |

---

## Cost Analysis
- **S3**: $0.023/month (first 50 TB)
- **DynamoDB**: ~$1.25/month (5 RCU/WCU)

## 1. State Management Architecture

### Why Two-Phase Bootstrap?
To avoid the "chicken-and-egg" problem of Terraform managing its own state.

| Phase | Tool | Purpose |
|-------|------|---------|
| 1. Bootstrap | AWS CLI | Create immutable foundation bucket |
| 2. Production Backend | Terraform | Create self-managed, protected state backend |

### The Bootstrap Project (`bootstrap/`)
- **Purpose**: Create `prod-tfstate-*` and `prod-terraform-locks`
- **Backend**: Uses CLI-created `tfstate-name` (never modify it)
- **Status**: One-time setup. Archive after success.
- **Recovery**: If production backend is deleted, re-run `terraform apply` in `bootstrap/`

### Why Not Import the CLI Bucket?
- The CLI bucket is **intentionally minimal** (no `prevent_destroy`)
- We use it only to bootstrap a **superior, Terraform-managed backend**
- This follows AWS Well-Architected Framework for IaC
graph TD
    A[CLI creates bootstrap-tfstate-xyz] --> B[bootstrap/ uses it]
    B --> C[Creates prod-tfstate-dog-cat]
    C --> D[All other projects use prod-tfstate-*]
    D --> E[bootstrap/ is archived] 