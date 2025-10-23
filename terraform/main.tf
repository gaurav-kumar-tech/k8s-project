data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "k8s_sg" {
  name_prefix = "k8s-kind-sg"
  
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_node" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.jenkins_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]
  
  tags = {
    Name = "k8s-kind-node"
  }
}

resource "null_resource" "install_tools" {
  depends_on = [aws_instance.k8s_node]
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = aws_instance.k8s_node.public_ip
  }
  
  provisioner "file" {
    source      = "../scripts/install-tools.sh"
    destination = "/home/ubuntu/install-tools.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/ubuntu/install-tools.sh"
    ]
  }
}

resource "null_resource" "setup_cluster" {
  depends_on = [null_resource.install_tools]
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = aws_instance.k8s_node.public_ip
  }
  
  provisioner "file" {
    source      = "../config/kind-config.yaml"
    destination = "/home/ubuntu/kind-config.yaml"
  }
  
  provisioner "file" {
    source      = "../scripts/setup-cluster.sh"
    destination = "/home/ubuntu/setup-cluster.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/setup-cluster.sh",
      "mkdir -p /home/ubuntu/.kube",
      "kind get kubeconfig --name=k8s-cluster > /home/ubuntu/.kube/config",
      "sed -i 's/127.0.0.1/${aws_instance.k8s_node.public_ip}/g' /home/ubuntu/.kube/config",
      "chmod 600 /home/ubuntu/.kube/config"
    ]
  }
}