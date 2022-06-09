.PHONY: generate
generate:
	@export GO111MODULE=on
	@export GOPROXY=https://goproxy.cn
	@go mod tidy
	@go generate ./...
	@echo "[OK] Generate all completed!"

gitTime=$(shell date +%Y%m%d%H%M%S)
gitCID=$(shell git rev-parse HEAD)

.PHONY: build
build: generate
	@cd cmd/client;CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.build=${gitTime}.${gitCID}" -o "../../bin/client"
	@echo "[OK] client binary was created!"
	@cd cmd/server;CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.build=${gitTime}.${gitCID}" -o "../../bin/server"
	@echo "[OK] server binary was created!"

.PHONY: test
test: 
	go test -v ./...