output "instance_public_ip" {
  description = "Public IP of the K8s node"
  value       = aws_instance.k8s_node.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.k8s_node.public_ip}"
}

output "web_app_url" {
  description = "Sample web application URL"
  value       = "http://${aws_instance.k8s_node.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from remote instance"
  value       = "scp -i ${var.ssh_private_key_path} ubuntu@${aws_instance.k8s_node.public_ip}:/home/ubuntu/.kube/config ./kubeconfig"
}

output "kubectl_access" {
  description = "How to access kubectl from local machine"
  value       = "export KUBECONFIG=./kubeconfig && kubectl get nodes"
}