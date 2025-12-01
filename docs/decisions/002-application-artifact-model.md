# 002 — Application Artifact Model

## Artifacts

**Decision:** An application is represented by exactly three artifacts:

- **frontend bundle** — a zip archive of compiled static assets (HTML, CSS, JS, images)
- **backend bundle** — a zip archive deployable to AWS Lambda
- **manifest** — a small YAML file that names the application and points at the two bundles

These three artifacts are sufficient to deploy a complete application. No other user-supplied configuration is required.

---

## Manifest

**Decision:** The manifest is a file named `app.yaml` with three required fields.

```yaml
name: my-app
frontend: ./frontend.zip
backend: ./backend.zip
```

| Field | Purpose |
|-------|---------|
| `name` | Identifier used to name all provisioned AWS resources |
| `frontend` | Path to the frontend bundle (relative to the manifest) |
| `backend` | Path to the backend bundle (relative to the manifest) |

Every field is read by the deploy flow. No optional fields are defined at this stage.

---

## Rationale

The vision requires that deployment feel closer to publishing a document than provisioning infrastructure. Three fields is the minimum that satisfies that:

- `name` is needed to namespace AWS resources across applications in the same cell.
- `frontend` and `backend` are needed to locate the artifacts to upload and deploy.

Everything else — the CloudFront distribution, API Gateway, Lambda function, S3 bucket, DynamoDB table — is determined by the platform, not the application.

---

## What Is Not Decided Here

- Bundle format constraints beyond "zip" (entry point naming, handler conventions)
- Manifest schema validation tooling
- How the manifest is located by the deploy CLI (working directory convention vs. explicit path)
