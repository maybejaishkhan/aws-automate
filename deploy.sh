#!/bin/bash

set -e

# --- Configuration ---
PRIVATE_KEY="terraform-key"
ANSIBLE_USER="ubuntu"
INVENTORY_FILE="hosts"

# --- Pre-flight Check ---
echo "🔎 Checking for SSH private key: $PRIVATE_KEY"
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "❌ Error: Private key '$PRIVATE_KEY' not found."
    echo "Please create it by running: ssh-keygen -t rsa -b 4096 -f $PRIVATE_KEY -N ''"
    exit 1
fi

# --- Set Key Permissions ---
echo "🔐 Setting secure permissions for the private key..."
chmod 400 "$PRIVATE_KEY"
echo "✅ Permissions set to 400 for $PRIVATE_KEY."

# --- Terraform Provisioning ---
echo "🚀 Initializing Terraform..."
terraform init -input=false

echo "🏗️ Applying Terraform plan... This may take a few minutes."
terraform apply -auto-approve

# --- Ansible Configuration ---
echo "✅ Terraform provisioning complete."
echo "🔎 Retrieving public IP address..."

PUBLIC_IP=$(terraform output -raw public_ip)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Error: Could not retrieve public IP address from Terraform output."
    exit 1
fi

echo "✅ Server IP is: $PUBLIC_IP"
echo "📝 Creating Ansible inventory file..."

# Create a dynamic inventory file for Ansible.
# We add ansible_ssh_common_args to ensure Ansible also only uses the specified key.
cat << EOF > $INVENTORY_FILE
[webserver]
$PUBLIC_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=./$PRIVATE_KEY ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentitiesOnly=yes'
EOF

echo "✅ Inventory file '$INVENTORY_FILE' created."

# --- Wait for SSH (FINAL FIX) ---
echo "⏳ Waiting for SSH to become available on $PUBLIC_IP..."
echo "(This can take a minute or two for the instance to boot and start sshd...)"

# This loop attempts to connect to the server's port 22.
# The key fix is adding '-o IdentitiesOnly=yes' to force SSH to use ONLY the
# key we specify with the -i flag, ignoring the ssh-agent.
until ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o ConnectionAttempts=1 -o ConnectTimeout=10 -i "$PRIVATE_KEY" "${ANSIBLE_USER}@${PUBLIC_IP}" echo "SSH is ready!" &>/dev/null; do
    printf "."
    sleep 5
done

echo "✅ SSH is up and ready!"

# --- Run Ansible Playbook ---
echo "⚙️ Running Ansible playbook to configure the server..."

# We no longer need to set ANSIBLE_HOST_KEY_CHECKING=False because it's handled
# in the inventory file now.
ansible-playbook -i $INVENTORY_FILE playbook.yml

# --- Finish ---
echo "🎉🚀 Deployment Complete! 🚀🎉"
echo ""
echo "You can access your web server at: http://$PUBLIC_IP"
echo "You can SSH into your server with: ssh -o IdentitiesOnly=yes -i $PRIVATE_KEY ${ANSIBLE_USER}@${PUBLIC_IP}"
echo "Once inside, run 'neofetch' to see system info."
