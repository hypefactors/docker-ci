IMAGE=hypefactors/docker-ci:latest

shell:
	docker run -it hypefactors/docker-ci:latest bash

build:
	docker build -t hypefactors/docker-ci:latest .
	docker history $(IMAGE) > build_log.txt
