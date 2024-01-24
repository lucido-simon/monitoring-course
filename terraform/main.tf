resource "helm_release" "nfs_client" {
  name       = "nfs"
  chart      = "nfs-subdir-external-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"

  set {
    name  = "nfs.server"
    value = var.nfs_server
  }
  set {
    name  = "nfs.path"
    value = var.nfs_path
  }
  set {
    name  = "storageClass.name"
    value = "nfs"
  }
  set {
    name  = "storageClass.defaultClass"
    value = var.nfs_sc_default
  }
}

resource "helm_release" "loki" {
  name             = "loki"
  chart            = "grafana-loki"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [helm_release.nfs_client]
}

resource "helm_release" "kube_prometheus_stack_release" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  values           = ["${file("${path.module}/../values/prometheus.values.yaml")}"]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [helm_release.nfs_client]
}

resource "kubernetes_manifest" "loki_ingress" {
  manifest = yamldecode("${file("${path.module}/../resources/loki-ingress.yaml")}")

  depends_on = [helm_release.loki]
}

resource "kubernetes_manifest" "grafana_ingress" {
  manifest = yamldecode("${file("${path.module}/../resources/grafana-ingress.yaml")}")

  depends_on = [helm_release.kube_prometheus_stack_release]
}

resource "kubernetes_manifest" "loki_datasource" {
  manifest = yamldecode("${file("${path.module}/../resources/loki-datasource.yaml")}")

  depends_on = [helm_release.kube_prometheus_stack_release, helm_release.loki]
}
