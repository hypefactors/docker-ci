IMAGE=hypefactors/docker-ci:php84

shell:
	docker run -it $(IMAGE) bash

publish:
	docker push $(IMAGE)

build:
	docker buildx build --platform=linux/amd64 -t $(IMAGE) .
	docker history $(IMAGE) > build_log.txt
