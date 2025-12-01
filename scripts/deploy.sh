#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

MANIFEST="${MANIFEST:-app.yaml}"
MANIFEST="$(realpath "$MANIFEST")"
MANIFEST_DIR="$(dirname "$MANIFEST")"

_field() {
  grep "^$1:" "$MANIFEST" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

CELL_NAME="$(_field name)"
FRONTEND_ZIP="$(realpath "$MANIFEST_DIR/$(_field frontend)")"
BACKEND_ZIP="$(realpath "$MANIFEST_DIR/$(_field backend)")"
DOMAIN="$(_field domain)"
HOSTED_ZONE_ID="$(_field hosted_zone_id)"

echo "Deploying cell '$CELL_NAME'..."
echo "  frontend: $FRONTEND_ZIP"
echo "  backend:  $BACKEND_ZIP"
[ -n "$DOMAIN" ] && echo "  domain:   $DOMAIN"

[ -d "$TERRAFORM_DIR/.terraform" ] || terraform -chdir="$TERRAFORM_DIR" init

terraform -chdir="$TERRAFORM_DIR" workspace select "$CELL_NAME" 2>/dev/null \
  || terraform -chdir="$TERRAFORM_DIR" workspace new "$CELL_NAME"

TERRAFORM_VARS="-var lambda_zip_path=$BACKEND_ZIP"
[ -n "$DOMAIN" ] && TERRAFORM_VARS="$TERRAFORM_VARS -var domain_name=$DOMAIN"
[ -n "$HOSTED_ZONE_ID" ] && TERRAFORM_VARS="$TERRAFORM_VARS -var hosted_zone_id=$HOSTED_ZONE_ID"

# shellcheck disable=SC2086
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve $TERRAFORM_VARS

BUCKET="$(terraform -chdir="$TERRAFORM_DIR" output -raw frontend_bucket_name)"
DIST_ID="$(terraform -chdir="$TERRAFORM_DIR" output -raw cloudfront_distribution_id)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
unzip -q "$FRONTEND_ZIP" -d "$WORK_DIR"
aws s3 sync "$WORK_DIR" "s3://$BUCKET" --delete

INVALIDATION_ID="$(aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --output text \
  --query 'Invalidation.Id')"

echo "Invalidation $INVALIDATION_ID created."
echo "App: $(terraform -chdir="$TERRAFORM_DIR" output -raw app_url)"
