.PHONY: generate
generate:
	@export GO111MODULE=on
	@export GOPROXY=https://goproxy.cn
	@go mod tidy
	@go generate ./...
	@echo "[OK] Generate all completed!"

gitTime=$(shell date +%Y%m%d%H%M%S)
gitCID=$(shell git rev-parse HEAD)

.PHONY: build.unidirectional
build.unidirectional: generate
	@cd cmd/unidirectional;CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.build=${gitTime}.${gitCID}" -o "../../bin/unidirectional"
	@echo "[OK] unidirectional binary was created!"

.PHONY: build.double-sided
build.double-sided: generate
	@cd cmd/double-sided/server;CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.build=${gitTime}.${gitCID}" -o "../../../bin/double-sided.server"
	@echo "[OK] double-sided.server binary was created!"
	@cd cmd/double-sided/client;CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.build=${gitTime}.${gitCID}" -o "../../../bin/double-sided.client"
	@echo "[OK] double-sided.client binary was created!"

.PHONY: test
test: 
	go test -v ./...

.PHONY: testgen
testgen:
	@./genBysh/.tests/test.sh
