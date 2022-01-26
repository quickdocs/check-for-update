all: build

build:
	docker build -t quickdocs/check-for-update .

run:
	docker run --rm -it -e GITHUB_TOKEN=$(GITHUB_TOKEN) quickdocs/check-for-update
