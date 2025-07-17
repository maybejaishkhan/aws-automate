#!/bin/bash
# =================================================================================
# Destruction Script
#
# This script tears down all infrastructure managed by Terraform in this
# directory and cleans up temporary files.
#
# Usage: ./destroy.sh
# =================================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🔥 Destroying all AWS resources managed by Terraform..."
echo "This action is irreversible."

# Run terraform destroy with auto-approval.
terraform destroy -auto-approve

echo "🧹 Cleaning up temporary files..."
rm -f hosts
rm -f terraform.tfstate*
rm -rf .terraform*

echo "✅ Cleanup complete."
