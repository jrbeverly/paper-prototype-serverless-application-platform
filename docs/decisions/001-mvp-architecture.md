# 001 — MVP Architecture

## IaC Tool: Terraform

**Decision:** Use Terraform.

**Note:** `VISION.md` lists AWS CloudFormation as the intended IaC tool. This is a conscious deviation. The devcontainer installs Terraform, and the only active linter (`TERRAFORM_TERRAFORM_FMT`) targets Terraform files. Aligning with the provided tooling is the practical choice for an MVP. CloudFormation may be revisited if the project later requires native AWS constructs unavailable in Terraform.

---

## Deployment Topology

**Decision:** One CloudFront distribution per application cell, with path-based routing:

- `/*` → S3 (static frontend)
- `/api/*` → API Gateway → Lambda (backend)

This is the minimum topology that satisfies the relative integration requirement from the vision: the frontend calls `/api/...` and CloudFront routes the request transparently. No CORS configuration, no environment-specific URLs.

---

## Backend Runtime

**Decision:** C# on AWS Lambda, targeting .NET 8.

The devcontainer installs .NET 8 and the vision specifies C#. Lambda supports .NET 8 natively.

---

## Frontend

**Decision:** Vue.js single-page application compiled to a static bundle and served from S3 via CloudFront.

---

## State / Persistence

**Decision:** One DynamoDB table per cell.

A single table is sufficient for MVP applications. The devcontainer includes a local DynamoDB instance for development.

---

## What Is Not Decided Here

- Multi-tenancy within a cell (not needed for first deploy)
- Custom domain names (CloudFront provides a default domain)
- Authentication (out of scope for the platform itself)
- Observability beyond Lambda and CloudFront defaults
