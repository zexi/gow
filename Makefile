STEAM_TAG := custom-20250922.0
CTR_GAME_CUSTOMIZE_IMAGE := registry.cn-beijing.aliyuncs.com/zexi/ctr-game-customize:2

build-steam:
	docker build -t registry.cn-beijing.aliyuncs.com/zexi/steam:$(STEAM_TAG) \
		--build-arg BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge \
		--build-arg CTR_GAME_CUSTOMIZE_IMAGE=$(CTR_GAME_CUSTOMIZE_IMAGE) \
		apps/steam/build
	docker push registry.cn-beijing.aliyuncs.com/zexi/steam:$(STEAM_TAG)

build-customize:
	docker buildx build --platform linux/arm64,linux/amd64  \
		-t $(CTR_GAME_CUSTOMIZE_IMAGE) . -f Dockerfile.customize --push

build-steam-xfce:
	docker build -t registry.cn-beijing.aliyuncs.com/zexi/steam:xfce-$(STEAM_TAG) \
		--build-arg BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge \
		--build-arg CTR_GAME_CUSTOMIZE_IMAGE=$(CTR_GAME_CUSTOMIZE_IMAGE) \
		apps/steam-xfce/build
	docker push registry.cn-beijing.aliyuncs.com/zexi/steam:xfce-$(STEAM_TAG)
