# AWS EC2 - Automated Configuration

This project contains a fully automated pipeline that deploys an Ubuntu EC2 instance on AWS with proper networking setup and security configurations using Terraform, Ansible and bash scripts.

## Step by Step Flow

- Bash Script
  - Checks for SSH private key.
  - Sets Key Permissions to 400.
  - **Terraform Provisioning** (`terraform init` then `terraform apply`)
    - Uses the AWS "provider".
    - Specifies the Ubuntu image with the "data" block.
    - Creates these with the "resource" blocks.
      - VPC (with the block 10.0.0.0/16)
      - Public Subnet (with the block 10.0.1.0/24)
      - Internet Gateway (for public internet access)
      - Route Table
      - Association (Route Table/Subnet)
      - Security Group
        - Inbound: Allow only `:22` (SSH) and `:80` HTTP.
        - Outbound: Allow all.
    - Uploads the public key (in the current folder) to AWS.
    - Create the EC2 instance (t2.micro).
    - Outputs the Public IP of the instance.
  - Bash: Saves terraform output (Public IP)
  - Creates inventory file for Ansible.
  - Waits for SSH to come up (tries after every 10 seconds)
  - **Ansible Configuration** (`ansible-playbook`)
    - Updates apt
    - Installs Nginx
    - Installs Neofetch
    - Makes sure that nginx service has started / is enabled on boot
    - ++ You Can Add More Tasks **

## Prerequisites

> This works on UNIX-based OSes (Linux, MacOS, WSL, FreeBSD) and Windows users would have to install/enable [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

You need to have an [AWS](https://aws.amazon.com/console/) Account (for free-tier EC2 instance). You also need to do some setup in your AWS account ([Sign Up](https://signin.aws.amazon.com/signup?request_type=register)).

1. **AWS Account Setup**
   1. Go to AWS and login as *root user*.
   2. Search for and go to **IAM** (Identity and Access Management).
   3. Go to the **Users** tab and click "Create User".
   4. Give it a name (terraform-user) and click **Next**.
   5. Choose "attach permissions directly", select the `AmazonEC2FullAccess` permission and click **Next**.
   6. Click "Create User".
   7. View the newly created User and in the "Summary" section click on **Create Access Key**.
   8. Choose "Command Line Interface" usecase, Check the confirmation box and click **Next**.
   9. Click "Create Access Key".
   10. Copy and save the **Access Key** and **Secret Access Key** (you can also download the .csv file).

<details>
    <summary><h4>Install AWS CLI, Terraform, Ansible (and Bash if needed)</h4></summary>

- **Linux**

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Add HashiCorp GPG key and repo
sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform and Ansible
sudo apt update && sudo apt install -y terraform ansible
```

- **MacOS**

```bash
brew tap hashicorp/tap
brew install awscli hashicorp/tap/terraform ansible
```

- **FreeBSD**

```bash
pkg install python3 py39-pip terraform ansible bash
pip install awscli --upgrade --user
# Add to path if needed
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.profile && source ~/.profile
```

- **Windows**: *Install WSL and inside it run the same commands as the Linux portion.*

---

</details>

- Configure AWS CLI - Run `aws configure` and then copy paste your **Access Key** and **Secret Access Key** (keep region and output to default).
- Run this to generate an SSH key (terraform-key):

    ```bash
    mkdir -p ~/.ssh
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-key
    ```

- Move your generated SSH key files inside the cloned project's folder.
- Lastly, add the keys to SSH agent.

    ```bash
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/
    ```

## Usage

> Make sure you've done everything in the [Prerequisites](#prerequisites) section.

1. Clone this repository and Navigate inside it.

    ```bash
    git clone https://github.com/maybejaishkhan/aws-automate
    cd ec2-automate
    ```

2. Run the `deploy.sh` script to deploy a free ec2 instance on your AWS account.

   ```bash
   bash deploy.sh
   ```

3. Run the `destroy.sh` script to destroy/terminate the instance.

   ```bash
   bash deploy.sh
   ```

## Files

- `main.tf` - Main Terraform configuration file containing all resource definitions
- `deploy.sh` - Shell script for deployment
- `destroy.sh` - Shell script for destroying resources
- `playbook.yml` - Ansible playbook for instance configuration

> The AWS security group is configured to allow inbound SSH and HTTP access from any IP (0.0.0.0/0). In a production environment, you should restrict these to specific IP (your IP).
