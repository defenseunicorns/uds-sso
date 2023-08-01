# renovate: datasource=docker depName=ghcr.io/defenseunicorns/packages/dubbd-k3d extractVersion=^(?<version>\d+\.\d+\.\d+)
DUBBD_K3D_VERSION := 0.5.2
ZARF_VERSION := v0.28.3
# renovate: datasource=docker depName=ghcr.io/defenseunicorns/uds-capability/uds-idam extractVersion=^(?<version>\d+\.\d+\.\d+)
IDAM_VERSION := 0.1.5
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

cluster/create:
	k3d cluster delete -c dev/k3d.yaml
	k3d cluster create -c dev/k3d.yaml

cluster/full: cluster/create build/all deploy/all  ## This will destroy any existing cluster, create a new one, then build and deploy all

build/all: build build/dubbd-pull-k3d.sha256 build/pull-idam.sha256 build/sso

build: ## Create build directory
	mkdir -p build

build/sso: | build ## Build SSO package
	cd sso && zarf package create --tmpdir=/tmp --architecture amd64 --confirm --output ../build

build/dubbd-pull-k3d.sha256: | build ## Download dubbd k3d oci package
	zarf package pull oci://ghcr.io/defenseunicorns/packages/dubbd-k3d:$(DUBBD_K3D_VERSION)-amd64 --oci-concurrency 9 --output-directory build
	echo "Creating shasum of the dubbd-k3d package"
	shasum -a 256 build/zarf-package-dubbd-k3d-amd64-$(DUBBD_K3D_VERSION).tar.zst | awk '{print $$1}' > build/dubbd-pull-k3d.sha256

build/pull-idam.sha256: | build ## Download idam
	# zarf package pull oci://ghcr.io/defenseunicorns/uds-capability/uds-idam:$(IDAM_VERSION)-amd64 --oci-concurrency 9 --output-directory build
	echo "Creating shasum of the idam package"
	shasum -a 256 build/zarf-package-uds-idam-amd64-$(IDAM_VERSION).tar.zst | awk '{print $$1}' > build/pull-idam.sha256

deploy/all: deploy/init deploy/metallb deploy/dubbd-k3d deploy/idam deploy/sso deploy/test

deploy/init:
	zarf init --components=git-server --confirm

deploy/dubbd-k3d: ## Deploy the k3d flavor of DUBBD
	cd ./build && zarf package deploy zarf-package-dubbd-k3d-amd64-$(DUBBD_K3D_VERSION).tar.zst --set=APPROVED_REGISTRIES="127.0.0.1* | ghcr.io/defenseunicorns/pepr* | ghcr.io/stefanprodan* | registry1.dso.mil" --confirm

deploy/idam: ## Deploy idam
	cd ./build && zarf package deploy zarf-package-uds-idam-amd64-*.tar.zst --confirm

deploy/sso: ## Deploy sso
	cd ./build && zarf package deploy --confirm zarf-package-uds-sso-amd64-*.tar.zst

deploy/metallb:
	cd dev/metallb && zarf package create --tmpdir=/tmp --architecture amd64 --confirm --output ../../build
	cd ./build && zarf package deploy -ltrace --tmpdir=/tmp --confirm zarf-package-metallb-amd64-*.tar.zst

deploy/test:
	cd dev/test-mission-app && zarf package create --tmpdir=/tmp --architecture amd64 --confirm --output ../../build
	cd ./build && zarf package deploy --tmpdir=/tmp --confirm zarf-package-podinfo-amd64-*.tar.zst
