# terraform-iap-cloudrun

## 概要

IAP（Identity-Aware Proxy）は、Google Cloud Platformのサービスに対して、Google Workspaceのユーザー認証を行うプロキシサービスです。

IAPをCloudRunの手前に配置すれば、指定したGoogleアカウントで認証できているリクエストのみがCloudRunに送られてきます。

IAPとCloudRunを連携させるにはLoadBalancerの設定も必要です。面倒な一通りの設定をterraformでできるようにしました。

## 詳しくは

https://www.tsuyukimakoto.com/blog/2024/07/07/iap-cloudrun-using-terraform/ を参照ください。
