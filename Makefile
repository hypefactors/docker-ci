IMAGE=hypefactors/docker-ci:php81

shell:
	docker run -it $(IMAGE) bash

publish:
	docker push $(IMAGE)

build:
	docker build -t $(IMAGE) .
	docker history $(IMAGE) > build_log.txt
