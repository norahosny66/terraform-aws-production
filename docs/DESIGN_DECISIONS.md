# Sprint 0

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


## DynamoDB vs S3 Native Locking

| Aspect | DynamoDB | S3 Native | Recommendation |
|--------|----------|-----------|----------------|
| **Maturity** | Production-ready (2017+) | Preview/Limited | Use DynamoDB |
| **Cost** | ~$0.25/month | Lower | DynamoDB for reliability |
| **Setup** | Requires separate table | Built-in | DynamoDB worth extra setup |
| **Monitoring** | CloudWatch metrics | Limited | DynamoDB for observability |
---

## Cost Analysis
- **S3**: $0.023/month (first 50 TB)
- **DynamoDB**: ~$1.25/month (5 RCU/WCU)

## State Management Architecture

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

# Sprint 1
## Networking

### Why Multi-AZ (3 subnets)?
- Survives single AZ failure (AWS SLA requirement)
- Required for RDS Multi-AZ and ASG high availability
- Cost impact: <$5/month difference

### Why Single NAT Gateway?
- Cost: $36/month vs $108/month for 3 NATs
- Sufficient for most workloads (< 5 Gbps)
- Can upgrade to multi-NAT if needed
- **Trade-off**: AZ failure breaks internet for all private subnets

### Why VPC Endpoint for S3?
- Avoids $0.01/GB NAT egress fees
- Blocks data exfiltration via public internet
- Required for HIPAA compliance (AWS Artifact)

### Why Default DENY Security Group?
- Principle of least privilege (PCI DSS 1.2.1)
- Prevents "accidental public" disasters
- Forces explicit security rules (no hidden open ports)
## VPC Flow Logs Design

### Why KMS Encryption?
- Required for HIPAA, PCI DSS, and GDPR compliance
- Prevents unauthorized access to log data
- Enables auditability of key usage

### Why 365-Day Retention?
- Meets FINRA 451 record retention requirements
- Allows long-term traffic pattern analysis
- Cost impact: <$5/month for typical VPC

### Why Least-Privilege IAM?
- Principle of least privilege (NIST 800-53)
- Limits blast radius if credentials are compromised
- Required for SOC 2 Type II audits

### 🔐 **AWS-Managed vs Customer-Managed KMS**
| Feature / Aspect          | **AWS-Managed KMS Key**                                                   | **Customer-Managed KMS Key (CMK)**                                                           |
| ------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Ownership**             | Created, and fully managed by AWS                                  | Created, owned, and managed by you                                                           |
| **Key Policy Control**    | No direct access to the key policy; tied to service permissions           | Full control over key policy (who can use, encrypt, decrypt, from where)                     |
| **Access Management**     | Controlled via service-level IAM permissions                              | Controlled via **both** IAM permissions **and** key policy                                   |
| **Rotation**              | Automatic rotation every 1 year by AWS                                    | Optional automatic annual rotation or manual rotation on-demand                              |
| **Auditability**          | Limited — usage tracked within the service but not directly in CloudTrail | Full usage audit in AWS CloudTrail (every encrypt/decrypt logged)                            |
| **Cross-Account Use**     | Not supported                                                             | Supported — can grant permissions to other AWS accounts                                      |
| **Deletion / Revocation** | Cannot delete AWS-managed keys; tied to the service lifecycle             | Can disable, schedule deletion, or revoke access instantly                                   |
| **Cost**                  | No monthly charge (only standard service usage costs)                     | \$1/month per key + API request costs                                                        |
| **Compliance**            | May not meet strict regulatory frameworks (PCI, HIPAA, FedRAMP, etc.)     | Meets strict compliance by giving you control over encryption and access                     |
| **Use Cases**             | General workloads, dev/test, low-sensitivity data                         | Regulated workloads, sensitive data, need for granular access control, cross-account sharing |
