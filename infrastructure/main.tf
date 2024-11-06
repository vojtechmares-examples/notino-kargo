data "digitalocean_kubernetes_versions" "doks" {
  version_prefix = "1.30."
}

resource "digitalocean_kubernetes_cluster" "foo" {
  name   = "notino-kargo"
  region = "fra1"
  version = data.digitalocean_kubernetes_versions.doks.latest_version

  # use default node pool, for demo it's mode than enough
  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.foo.kube_config.0.raw_config
  sensitive = true
}

data "cloudflare_zone" "maresdemo" {
  name = "maresdemo.com"
}

data "cloudflare_api_token_permission_groups" "all" {}

variable "cloudflare_account_id" {
  type = string
}

resource "cloudflare_api_token" "dns_edit_maresdemo" {
  name = "external-dns"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = jsonencode({
        "com.cloudflare.api.account.zone.${data.cloudflare_zone.maresdemo.id}" = "*"
      })
    }
  }

  expires_on = "2024-11-10T00:00:00Z"
}

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }

  depends_on = [
    digitalocean_kubernetes_cluster.foo,
    cloudflare_api_token.dns_edit_maresdemo,
  ]
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }

  depends_on = [
    digitalocean_kubernetes_cluster.foo,
  ]
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [
    digitalocean_kubernetes_cluster.foo,
  ]
}

resource "kubernetes_secret_v1" "external_dns_cloudflare_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace_v1.external_dns.metadata.0.name
  }

  data = {
    token = cloudflare_api_token.dns_edit_maresdemo.value
  }

  depends_on = [
    cloudflare_api_token.dns_edit_maresdemo,
    kubernetes_namespace_v1.external_dns,
  ]
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
  version    = "4.11.3"

  values = [
    file("${path.module}/values/ingress-nginx.yaml"),
  ]

  depends_on = [
    kubernetes_namespace_v1.ingress_nginx,
  ]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata.0.name
  version    = "1.16.1"

  values = [
    file("${path.module}/values/cert-manager.yaml"),
  ]

  depends_on = [
    kubernetes_namespace_v1.cert_manager,
  ]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = kubernetes_namespace_v1.external_dns.metadata.0.name
  version    = "1.15.0"

  values = [
    file("${path.module}/values/external-dns.yaml"),
  ]

  depends_on = [
    kubernetes_namespace_v1.external_dns,
    kubernetes_secret_v1.external_dns_cloudflare_token,
  ]
}

resource "kubernetes_secret_v1" "cert_manager_cloudflare_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace_v1.cert_manager.metadata.0.name
  }

  data = {
    token = cloudflare_api_token.dns_edit_maresdemo.value
  }

  depends_on = [
    cloudflare_api_token.dns_edit_maresdemo,
    kubernetes_namespace_v1.cert_manager,
  ]
}

resource "kubectl_manifest" "cluster_issuer_letsencrypt_production" {
  depends_on = [
    helm_release.cert_manager,
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    email: nobody@maresdemo.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
YAML
}

resource "kubectl_manifest" "cluster_issuer_letsencrypt_staging" {
  depends_on = [
    helm_release.cert_manager,
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: nobody@maresdemo.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
YAML
}

resource "kubectl_manifest" "cluster_issuer_letsencrypt_dns_production" {
  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret_v1.cert_manager_cloudflare_token,
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns-production
spec:
  acme:
    email: nobody@maresdemo.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-dns-production
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: token
YAML
}
