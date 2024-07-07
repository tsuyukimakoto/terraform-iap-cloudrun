# 変数の定義
TAG = latest
PROJECT_ID = GoogleProjectID
ARTIFACT_REGISTRY = asia-northeast1-docker.pkg.dev
REPOSITORY_NAME = ARTIFACT_REPOSITORY_NAME
IMAGE_NAME = IMAGE_NAME
SERVICE_NAME = CLOUD_RUN_SERVICE_NAME
REGION = asia-northeast1

# Docker imageのbuildとtag付けを行うコマンド
build:
	docker build --platform linux/amd64 . -t $(IMAGE_NAME):latest

# Docker imageをgoogle cloudのartifact registryにpushするコマンド
push:
	docker tag $(IMAGE_NAME) $(ARTIFACT_REGISTRY)/$(PROJECT_ID)/$(REPOSITORY_NAME)/$(IMAGE_NAME):latest && \
	docker push $(ARTIFACT_REGISTRY)/$(PROJECT_ID)/$(REPOSITORY_NAME)/$(IMAGE_NAME):latest

# Cloud Runのサービスを起動するコマンド
deploy:
	gcloud run deploy $(SERVICE_NAME) --image $(ARTIFACT_REGISTRY)/$(PROJECT_ID)/$(REPOSITORY_NAME)/$(IMAGE_NAME):latest --region $(REGION)

# すべてのコマンドを一度に実行するコマンド
all: build push deploy
