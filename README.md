# Ansible Lab

This Terraform script automatically provisions an Ansible Sandbox environment in
AWS. It creates a custom VPC with multiple Ubuntu EC2 instances deployed on
public subnet and configures them as Ansible Slaves. The scipt generates all
necessary configuration files (`inventory` and `ansible.cfg`), allowing user to
start writing/experimenting with Ansible playbooks on local machine straight
away.

## Prerequisites

- SSH key pair generated. The script expects it to be present on
  `~/.ssh/id_rsa.pub`
- AWS credentials exported
- Ansible
- Terraform

## Usage

### Scaling the Slaves

- To scale the Ansible slaves to your liking, modify the count and instance_type
  on `terraform.tfvars`.

### Testing connectivity

- After succesful apply, you should be able to connect to all slaves:
  `ansible all -m ping`

- To verify SSH access: `ssh ubuntu@<instance-public-ip>`
