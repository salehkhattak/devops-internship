resource "minikube_cluster" "cluster" {

  cluster_name = var.cluster_name

  driver = var.driver

  cpus = var.cpus

  memory = var.memory

  kubernetes_version = var.kubernetes_version
}