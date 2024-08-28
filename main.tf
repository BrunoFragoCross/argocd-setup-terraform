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
  filename = "secrets/privateKeyPem.pem"
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

  /*provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y", //update linux
      //docker block
      "sudo dnf install docker -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker $USER && newgrp docker",
      //k8s block
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
      "chmod +x kubectl",
      "sudo mv kubectl /usr/local/bin/",
      "kubectl version --client -o json",
      //minikube block
      "wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "chmod +x minikube-linux-amd64",
      "sudo mv minikube-linux-amd64 /usr/local/bin/minikube",
      "minikube version",
      "minikube start --driver=docker",
      "minikube status",
      //argoCD block
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64",
      "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",
      "rm argocd-linux-amd64"
    ]
  }*/
}

//to let ssh access
resource "aws_security_group" "ingress-ssh" {
  name = "allow-my-ip-ssh"
}

resource "aws_vpc_security_group_egress_rule" "all_ports_open" {
  security_group_id =  aws_security_group.ingress-ssh.id

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