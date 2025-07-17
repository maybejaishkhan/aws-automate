#!/bin/bash

set -e

# Log Functions -------------------------------------------
log()        { echo -e "[+] $1"; }
log_ok()     { echo -e "[\033[0;32mDONE\033[0m] $1"; }
log_fail()   { echo -e "[\033[0;31mFAIL\033[0m] $1"; }
log_wait()   { echo -e "[\033[0;33mWAIT\033[0m] $1"; }

# Variables -----------------------------------------------
PRIVATE_KEY="terraform-key"
ANSIBLE_USER="ubuntu"
INVENTORY_FILE="hosts"

# Pre-Checking --------------------------------------------
log "Checking for SSH private key: $PRIVATE_KEY"
if [ ! -f "$PRIVATE_KEY" ]; then
    log_fail "Private key '$PRIVATE_KEY' not found."
    echo "Please create it by running: ssh-keygen -t rsa -b 4096 -f $PRIVATE_KEY"
    exit 1
fi

# Set Key Permissions -------------------------------------
log "Setting secure permissions for the private key..."
chmod 400 "$PRIVATE_KEY"
log_ok "Permissions set to 400 for $PRIVATE_KEY."

# Terraform Provisioning ----------------------------------
log "Initializing Terraform..."
terraform init -input=false

log "Applying Terraform plan... This may take a few minutes."
terraform apply -auto-approve
log_ok "Terraform provisioning complete."

# Ansible Configuration -----------------------------------
log "Retrieving public IP address..."

PUBLIC_IP=$(terraform output -raw public_ip)

if [ -z "$PUBLIC_IP" ]; then
    log_fail "Error: Could not retrieve public IP address from Terraform output."
    exit 1
fi

log_ok "Server IP is: $PUBLIC_IP"
log "Creating Ansible inventory file..."

# Create a dynamic inventory file for Ansible. Added ansible_ssh_common_args to ensure Ansible also only uses the specified key.
cat << EOF > $INVENTORY_FILE
[webserver]
$PUBLIC_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=./$PRIVATE_KEY ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentitiesOnly=yes'
EOF

log_ok "Inventory file '$INVENTORY_FILE' created."

# Wait for SSH ------------------------------------------------
log_wait "Waiting for SSH to become available on $PUBLIC_IP..."
echo "(This can take a minute or two for the instance to boot and start sshd...)"
until ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ConnectionAttempts=1 -o ConnectTimeout=10 -i "$PRIVATE_KEY" "${ANSIBLE_USER}@${PUBLIC_IP}" echo "SSH is ready!" &>/dev/null; do
    printf "."
    sleep 5
done

log_ok "SSH is up and ready!"

# Run Ansible Playbook ----------------------------------------
log "Running Ansible playbook to configure the server..."
ansible-playbook -i $INVENTORY_FILE playbook.yml

# Finish ------------------------------------------------------
log_ok "🎉🚀 Deployment Complete! 🚀🎉"
echo ""
echo "You can access your web server at: http://$PUBLIC_IP"
echo "You can SSH into your server with: ssh -o IdentitiesOnly=yes -i $PRIVATE_KEY ${ANSIBLE_USER}@${PUBLIC_IP}"
echo "Once inside, run 'neofetch' to see system info."
