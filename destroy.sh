#!/bin/bash

set -e

# Log Functions -------------------------------------------
log()        { echo -e "[+] $1"; }
log_ok()     { echo -e "[\033[0;32mDONE\033[0m] $1"; }

log "Destroying all AWS resources managed by Terraform..."
echo "This action is irreversible."

# Run terraform destroy with auto-approval.
terraform destroy -auto-approve

log "Cleaning up temporary files..."
rm -f hosts
rm -f terraform.tfstate*
rm -rf .terraform*

log_ok "Cleanup complete."
