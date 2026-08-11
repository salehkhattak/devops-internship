output "cluster_name" {
  value = minikube_cluster.cluster.cluster_name
}

output "kubeconfig" {
  value = minikube_cluster.cluster.kubeconfig
}