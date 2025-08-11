# VPC Terraform Module

## 📜 Overview
This module provisions a **production-grade AWS VPC** with:
- Public and private subnets across multiple Availability Zones.
- Internet Gateway and NAT Gateways for controlled internet access.
- Route tables with explicit public/private routing.
- **VPC Flow Logs** sent to **CloudWatch Logs** with **Customer-Managed KMS (CMK)** encryption for maximum security.
- Least-privilege IAM roles and policies for logging.

---

## 🚀 Features
- **Multi-AZ architecture** for high availability.
- **Customer-Managed KMS Key** for log encryption with rotation enabled.
- **CloudWatch Logs retention** set to 365 days for compliance.
- **Prevent destroy** lifecycle on critical log groups.
- **IAM Least Privilege** for VPC Flow Logs write permissions.

---

## 🔐 Security Best Practices Implemented
| Feature | Why it Matters |
|---------|----------------|
| **CMK (Customer-Managed Key)** | Full control over encryption policies, key rotation, and auditability. |
| **Key rotation enabled** | Reduces risk if a key is compromised. |
| **Explicit IAM trust policy** | Prevents privilege escalation. |
| **Prevent log group destruction** | Avoids accidental deletion of audit logs. |
| **Scoped IAM permissions** | Only allow the needed actions for Flow Logs. |

---

## 📦 Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources | `string` | n/a | ✅ |
| `region` | AWS region | `string` | `us-east-1` | ❌ |
| `tags` | Common resource tags | `map(string)` | `{}` | ❌ |

---

## 📤 Outputs
| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `flow_log_group_arn` | ARN of the CloudWatch Log Group for VPC Flow Logs |

---
## 🛡 Checkov Compliance
This module passes [Checkov](https://www.checkov.io/) static analysis with all critical and high-severity policies enabled.

**Key Compliance Points:**
- ✅ VPC Flow Logs are enabled and encrypted using a customer-managed KMS key
- ✅ CloudWatch log groups have retention set (365 days)
- ✅ KMS key rotation enabled
- ✅ IAM policies follow least-privilege

---
## 🛠 Usage Example
```hcl
module "vpc" {
  source = "../../modules/vpc"

  name   = "prod-network"
  region = "us-east-1"
  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

