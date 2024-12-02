module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "ansible-sandbox-lab"
  cidr = var.vpc_cidr

  azs            = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  public_subnets = var.public_subnets

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible-lab-sg"
  description = "Security group used for ansible sandbox lab"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "hensu-maci-access"
  public_key = file("~/.ssh/id_rsa.pub") # Public key needs to be present on your machine
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS ID, never changes

  filter {
    name = "name"
    # https://cloud-images.ubuntu.com/locator/
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_instance" "ansible_slave" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname ansible-slave-${count.index + 1}
              EOF

  tags = {
    Name = "ansible-slave-${count.index + 1}"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory"
  content  = <<-EOF
    [ansible_nodes]
    %{for instance in aws_instance.ansible_slave~}
    ${instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
    %{endfor~}
    EOF
}

resource "local_file" "ansible_config" {
  filename = "${path.module}/ansible.cfg"
  content  = <<-EOF
    [defaults]
    inventory = inventory
    host_key_checking = False
    remote_user = ubuntu
    private_key_file = ~/.ssh/id_rsa
    
    [ssh_connection]
    pipelining = True
    EOF
}

# outputs.tf
# output "vpc_id" {
#   value = module.vpc.vpc_id
# }
#
# output "public_subnet_id" {
#   value = module.vpc.public_subnets[0]
# }

output "slave_public_ips" {
  value = aws_instance.ansible_slave[*].public_ip
}

# output "ansible_access_test" {
#   value = <<EOF
# ssh -i ${var.private_key_location} ubuntu@${aws_instance.ansible_master.public_ip}
#
# # Test ansible:
# ansible all -m ping
# EOF
# }

