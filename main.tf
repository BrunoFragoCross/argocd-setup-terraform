provider "aws" {
  region                   = "us-west-2"
  shared_credentials_files = ["C:\\Users\\BrunoFragomeni\\.aws\\credentials"]
  profile                  = "mfa"
}

# Terraform Data Block - get linux image
data "aws_ami" "amazon_linux_2023" {
  /*filter {
    name   = "name"
    values = ["al2023-ami-2023.5.20240819.0-kernel-6.1-x86_64"]
  }*/
  filter {
    name   = "image-id"
    values = ["ami-02d3770deb1c746ec"]
  }
}

//to generate key pair to access linux vm
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "aws_key_pair" "amazon_linux_vm" {
  key_name   = "AmazongLinuxKeyPair"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

//to spit the private key for putty login
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "${path.module}/secrets/privateKeyPem.pem"
}

resource "aws_instance" "linux_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.large"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.amazon_linux_vm.key_name
  connection {
    user        = "ec2-user"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  vpc_security_group_ids = [aws_security_group.ingress-ssh.id]

  lifecycle {
    ignore_changes = [security_groups]
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 12
    volume_type           = "gp3"
  }

  tags = {
    Name = "minikube"
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/home/ec2-user/"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "sudo chmod +x /home/ec2-user/scripts/startup-main.sh",
      "sudo /home/ec2-user/scripts/startup-main.sh",
    ]
  }
  
}

//to let ssh access
resource "aws_security_group" "ingress-ssh" {
  name = "allow-my-ip-ssh"
}

resource "aws_vpc_security_group_egress_rule" "all_ports_open" {
  security_group_id = aws_security_group.ingress-ssh.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

resource "aws_vpc_security_group_ingress_rule" "port_22_open_to_me" {
  security_group_id = aws_security_group.ingress-ssh.id

  cidr_ipv4   = "${var.my_public_ip}/32" //this is my ip
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

//to access the argocd ui
resource "aws_vpc_security_group_ingress_rule" "port_8080_open_to_me" {
  security_group_id = aws_security_group.ingress-ssh.id

  cidr_ipv4   = "${var.my_public_ip}/32" //this is my ip
  from_port   = 8080
  ip_protocol = "tcp"
  to_port     = 8080
}

//for grafana server at the end of the course, remember to access via http, instead of https
resource "aws_vpc_security_group_ingress_rule" "port_3000_open_to_me" {
  security_group_id = aws_security_group.ingress-ssh.id

  cidr_ipv4   = "${var.my_public_ip}/32" //this is my ip
  from_port   = 3000
  ip_protocol = "tcp"
  to_port     = 3000
}