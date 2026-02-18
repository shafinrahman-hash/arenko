# Technical exercise 

As I did not want to use any development AWS accounts from my current organization, I validated the Terraform configuration by running it up to terraform plan using placeholder credentials. During this process, I reviewed and refined the configuration to improve correctness, consistency, and production readiness.

Key improvements made:

• Fixed all issues initially reported by Terraform during planning.
• Standardized resource naming conventions and prefixes for consistency.
• Normalized subnet CIDR allocations and corrected related networking configurations.
• Resolved multiple security group misconfigurations, including rule whitelisting and subnet placement.
• Enabled deletion protection for the Application Load Balancer (ALB).
• Configured ALB access logging with S3 as the backend.
• Enhanced tagging strategy to support environment cost tracking and governance.
• Enforced HTTPS by redirecting HTTP traffic to HTTPS (with a temporary workaround due to the absence of an ACM certificate ARN).
• Updated the load balancer target group configuration to align with ECS Fargate best practices.
• Added missing security groups and corrected AWS resource misconfigurations (e.g., Elastic IP setup).
• Corrected the PostgreSQL port configuration to 5432.
• Moved the RDS instance from public to private subnets to improve security.
• Fixed Terraform outputs for usability and integration.
• Optimized the `variables.tf` structure for better clarity and reusability.

Additionally, I included a template configuration for an S3 remote backend (not executed due to lack of AWS access), incorporating:

• DynamoDB-based state locking.
• S3 versioning for Terraform state protection.
• Lifecycle rules to transition older state versions to cheaper storage after 30 days.
• Automatic expiration of older state versions after 180 days to control storage growth.
• Cleanup of incomplete multipart uploads after 7 days.

These changes focus on improving reliability, security, maintainability, and production readiness while ensuring the configuration remains reusable and aligned with infrastructure best practices.

