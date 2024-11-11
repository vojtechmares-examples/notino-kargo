terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.43"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.45"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

variable "digitalocean_token" {
  sensitive = true
}

provider "digitalocean" {
  token = var.digitalocean_token
}


variable "cloudflare_token" {
  sensitive = true
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.foo.kube_config.0.host
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.foo.kube_config.0.cluster_ca_certificate)
    token                  = digitalocean_kubernetes_cluster.foo.kube_config.0.token
  }
}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.foo.kube_config.0.host
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.foo.kube_config.0.cluster_ca_certificate)
  token                  = digitalocean_kubernetes_cluster.foo.kube_config.0.token
}

provider "kubectl" {
  host                   = digitalocean_kubernetes_cluster.foo.kube_config.0.host
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.foo.kube_config.0.cluster_ca_certificate)
  token                  = digitalocean_kubernetes_cluster.foo.kube_config.0.token
  load_config_file       = false
}
