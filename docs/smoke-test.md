# End-to-end Smoke Test

Validates the full platform lifecycle from scratch: build the reference
application, provision a cell, and verify that a real user flow works over a
single URL. A second cell is provisioned to confirm isolation.

This procedure is the MVP's definition of done.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | ≥ 1.9 | Provision AWS infrastructure |
| .NET SDK | 8 | Build the Lambda package |
| Node.js | 20 | Build the Vue frontend |
| AWS CLI | v2 | Sync S3, create CloudFront invalidation |

AWS credentials must be configured (environment variables, `~/.aws/credentials`,
or an IAM instance profile) with permissions to create resources in Lambda, API
Gateway, CloudFront, S3, DynamoDB, and IAM.

```bash
aws sts get-caller-identity   # confirm credentials are active
```

---

## Step 1 — Build the artifacts

```bash
make build
```

This produces:
- `frontend/dist/` — compiled Vue SPA
- `backend/backend.zip` — self-contained Lambda package

Zip the frontend bundle (the deploy flow expects a zip):

```bash
(cd frontend/dist && zip -r ../../frontend.zip .)
```

---

## Step 2 — Create a manifest for cell A

```bash
cat > smoke-a.yaml <<'EOF'
name: smoke-a
frontend: ./frontend.zip
backend: ./backend/backend.zip
EOF
```

The `name` field becomes the Terraform workspace name and is used to prefix
every AWS resource (`smoke-a-items`, `smoke-a-frontend`, `smoke-a-api`, …).

---

## Step 3 — Deploy cell A

```bash
make deploy MANIFEST=smoke-a.yaml
```

The deploy script will:
1. Run `terraform init` if needed.
2. Select (or create) the `smoke-a` Terraform workspace.
3. Apply the full stack — DynamoDB table, Lambda function, API Gateway HTTP
   API, S3 bucket, and CloudFront distribution.
4. Sync the frontend bundle to the S3 bucket.
5. Create a CloudFront cache invalidation.
6. Print the cell URL.

> First apply takes ~5 minutes while CloudFront provisions the distribution.
> Subsequent deploys are faster.

Copy the printed URL, for example `https://d1234abcd.cloudfront.net`.

---

## Step 4 — Run the smoke test against cell A

```bash
./scripts/smoke-test.sh https://d1234abcd.cloudfront.net
```

Expected output:

```
==> Smoke-testing https://d1234abcd.cloudfront.net

--- Frontend
  [PASS] GET / returns 200

--- Backend round-trip
  [PASS] POST /api/items returns 201
  [PASS] GET /api/items contains the created item

==> Results: 3 passed, 0 failed
```

The three checks map directly to the acceptance criteria:

| Check | Acceptance criterion |
|-------|---------------------|
| `GET /` returns 200 | Frontend loads and is served from CloudFront/S3 |
| `POST /api/items` returns 201 | Frontend reaches the backend via relative `/api/*` path through CloudFront → API Gateway → Lambda |
| `GET /api/items` contains the created item | Data round-trips through DynamoDB |

---

## Step 5 — Deploy a second cell and verify isolation

Create a manifest for cell B:

```bash
cat > smoke-b.yaml <<'EOF'
name: smoke-b
frontend: ./frontend.zip
backend: ./backend/backend.zip
EOF
```

Deploy it — **no application code is touched**:

```bash
make deploy MANIFEST=smoke-b.yaml
```

Cell B provisions a completely independent set of AWS resources in a new
Terraform workspace. Copy the second URL and verify its DynamoDB table is
empty (no data from cell A):

```bash
curl -s https://<cell-b-url>/api/items
# → []
```

Run the smoke test against cell B to confirm it is fully functional on its own:

```bash
./scripts/smoke-test.sh https://<cell-b-url>
```

Both cells use identical code and infrastructure templates but are completely
isolated — separate DynamoDB tables, S3 buckets, Lambda functions, and
CloudFront distributions. Data written to one cell never appears in the other.

---

## Tear down

```bash
# Destroy cell A
terraform -chdir=terraform workspace select smoke-a
terraform -chdir=terraform destroy -auto-approve \
  -var "lambda_zip_path=$(pwd)/backend/backend.zip"

# Destroy cell B
terraform -chdir=terraform workspace select smoke-b
terraform -chdir=terraform destroy -auto-approve \
  -var "lambda_zip_path=$(pwd)/backend/backend.zip"
```

> `backend/backend.zip` must exist when running destroy because Terraform
> evaluates `filebase64sha256()` during the plan phase. Run `make build-backend`
> first if the file has been removed.
