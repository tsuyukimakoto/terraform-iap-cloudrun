# ここを変更する
locals {
  # Google Cloud Consoleのダッシュボードに表示されています。おそらく12桁の数字
  account_no = "62578840968"
  # Google CloudのプロジェクトID（表示名と違ってsaffixの数字がついていることがあるので注意）
  project  = "iapcloudruntest202407"
  # regionは好きに設定してください
  region   = "asia-northeast1"
  # CloudRunとArtifact Registryで利用するロケーションです
  location = "asia-northeast1"
  # Artifact Registryのリポジトリ名
  google_artifact_registry_repository_name = format(
    "iap-cloudrun-%s",
    random_id.suffix.hex,
  )
  # CloudRunにデプロイする際のサービス名suffix無しのわかりやすい名前でも良いかも
  cloudrun_service_name = format(
    "iap-cloudrun-%s",
    random_id.suffix.hex,
  )
  # アプリケーションへアクセスする際のドメイン名
  domain = "iaprun.everes.net"
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_web_backend_service_iam#member/members
  # internalなIAPを利用するので、CloudIdentityやGoogle Workspaceの組織ユーザーでなければいけません。Google Groupやドメインなどの指定もできると書かれています
  iap_member_groups = [
    "user:makoto@everes.net",
  ]
  # IAPのサポートメールアドレス
  support_email = "makoto@everes.net"
}
provider "google" {
  project = local.project
  region  = local.region
}

provider "google-beta" {
  project = local.project
  region  = local.region
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "ssl_cert" {
  source = "../../modules/certificate"
  project = local.project
  domain  = local.domain
}

# terraformを実行した後に以下のコマンドの実行が必要
# 実施前にWebアクセスすると The IAP service account is not provisioned. というエラーになる
# gcloud beta services identity create --service=iap.googleapis.com
module "iap" {
  source = "../../modules/iap"
  project = local.project
  support_email = local.support_email
}

module "cloudrun" {
  source = "../../modules/cloudrun"
  account_no = local.account_no
  project = local.project
  location = local.location
  region = local.region
  suffix = random_id.suffix.hex
  cloudrun_service_name = local.cloudrun_service_name
  google_artifact_registry_repository_name = local.google_artifact_registry_repository_name
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"
  project = local.project
  region = local.region
  suffix = random_id.suffix.hex
  cloudrun_service_name = module.cloudrun.service_name
  ssl_certificate_id = module.ssl_cert.ssl_certificate_id
  ssl_policy_id = module.ssl_cert.ssl_policy_id
  iap_member_groups = local.iap_member_groups
  iap_client_id = module.iap.google_iap_client_client_id
  iap_client_secret = module.iap.google_iap_client_secret
  domain = local.domain
}