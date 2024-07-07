variable "account_no" {}
variable "project" {}
variable "location" {}
variable "region" {}
variable "suffix" {}
variable "cloudrun_service_name" {}
variable "google_artifact_registry_repository_name" {}

output "service_name" {
  value = google_cloud_run_service.this.name
}

resource "google_cloud_run_service" "this" {
  # cloudコマンドでCloud Runへデプロイする際にはこの名前を使うので、適切な名前にしましょう
  name     = var.cloudrun_service_name
  location = var.location
  metadata {
    annotations = {
      # Cloud Runへのアクセスは内部からか、Cloud Load Balancerを経由したもののみに制限する
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing",
    }
  }
  template {
    metadata {
      annotations = {
        # 費用的にインスタンス数を制限したい場合にはここで設定する
        "autoscaling.knative.dev/maxScale" = "1",
      }
    }
    spec {
      # Cloud Runのサービスアカウント。Cloud Runに権限をつけたい場合にはこのユーザーに権限を付与すれば良い
      service_account_name = google_service_account.cloudrun_service_account.email
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
        # artifact registryのイメージを指定する場合はこういうパスになる
        # image = format(
        #   "asia-northeast1-docker.pkg.dev/%s/%s/%s:latest",
        #   var.project_id,
        #   var.google_artifact_registry_repository_name,
        #   var.image_name
        # )
      }
    }
  }
  lifecycle {
    # terraform外からCloud Runに別のイメージをデプロイしても、terraformが変更を検知しないようにする
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/client-name"],
      metadata[0].annotations["run.googleapis.com/client-version"],
      template[0].spec[0].containers[0].image,
    ]
  }
}

# Cloud Runのサービスアカウント
resource "google_service_account" "cloudrun_service_account" {
  account_id = format(
    "forcloudrun-%s",
    var.suffix,
  )
  display_name = "Cloud Run Service Account"
}

# Serverless NEGに対するIAMポリシーの設定
resource "google_project_iam_member" "neg_iam" {
  project = var.project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.cloudrun_service_account.email}"
}

# Artifact Registryのリポジトリ。ここにDockerイメージを保存する
resource "google_artifact_registry_repository" "cloudrun_repository" {
  provider      = google
  location      = var.location
  repository_id = var.google_artifact_registry_repository_name
  format        = "DOCKER"
}

# IAPからCloud Runを起動できるようにする。IAPの設定が終わっていることが前提なので、最初にterraform applyした時点では失敗する
resource "google_cloud_run_service_iam_binding" "iap_invoker" {
  project    = var.project
  location   = google_cloud_run_service.this.location
  service    = google_cloud_run_service.this.name
  role       = "roles/run.invoker"

  members = [
    # account_noを別の何かから取れれば…。ダッシュボードに表示されている
    "serviceAccount:service-${var.account_no}@gcp-sa-iap.iam.gserviceaccount.com"
  ]
}