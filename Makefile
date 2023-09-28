# renovate: datasource=docker depName=ghcr.io/defenseunicorns/packages/dubbd-k3d extractVersion=^(?<version>\d+\.\d+\.\d+)
DUBBD_K3D_VERSION := 0.9.0

# renovate: datasource=github-tags depName=defenseunicorns/zarf
ZARF_VERSION := v0.29.2

# renovate: datasource=github-tags depName=defenseunicorns/uds-package-metallb
METALLB_VERSION := 0.0.1

# renovate: datasource=docker depName=ghcr.io/defenseunicorns/uds-capability/uds-idam extractVersion=^(?<version>\d+\.\d+\.\d+)
IDAM_VERSION := 0.1.11

# x-release-please-start-version
SSO_VERSION := 0.1.3
# x-release-please-end

ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

cluster/create:
	k3d cluster delete -c dev/k3d.yaml
	k3d cluster create -c dev/k3d.yaml

cluster/full: cluster/create build/all deploy/all  ## This will destroy any existing cluster, create a new one, then build and deploy all

cluster/bundle: cluster/create build/bundle deploy/bundle ## Create k3d cluster, build SSO uds bundle, and deploy that bundle to created cluster

build/all: build build/sso build/bundle ## Build both the zarf package for only SSO and also the SSO uds bundle

build: ## Create build directory
	mkdir -p build

build/sso: | build ## Build SSO package
	cd sso && zarf package create --tmpdir=/tmp --architecture amd64 --confirm --output ../build

build/bundle: | build ## Build SSO uds bundle as defined in dev/uds-bundle.yaml
	cd dev && uds bundle create --set INIT_VERSION=$(ZARF_VERSION) --set METALLB_VERSION=$(METALLB_VERSION) --set DUBBD_VERSION=$(DUBBD_K3D_VERSION) --set IDAM_VERSION=$(IDAM_VERSION) --confirm

deploy/sso: ## Deploy only the sso zarf package
	cd dev && zarf package deploy zarf-package-uds-sso-amd64-*.tar.zst --confirm

deploy/bundle: ## Deploy the SSO uds bundle
	cd dev && uds bundle deploy uds-bundle-uds-sso-amd64-*.tar.zst --confirm


# Build all CI Test requirements (SSO from source, uds bundle with zarf / metallb / dubbd / idam)
build/all-ci: build build/sso build/ci-upgrade-sso-published build/ci-upgrade-sso-source

# Build the CI upgrade test setup bundle (zarf / metallb / dubbd / idam)
build/ci-upgrade-sso-published: | build
	cd test/ci-upgrade-sso && uds bundle create --set SSO_VERSION=$(SSO_VERSION) --set INIT_VERSION=$(ZARF_VERSION) --set METALLB_VERSION=$(METALLB_VERSION) --set DUBBD_VERSION=$(DUBBD_K3D_VERSION) --set IDAM_VERSION=$(IDAM_VERSION) --confirm

# Build the CI upgrade test for source SSO image
build/ci-upgrade-sso-source: | build
	cd test/ci-upgrade-sso/source-sso && uds bundle create --set INIT_VERSION=$(ZARF_VERSION) --set METALLB_VERSION=$(METALLB_VERSION) --set DUBBD_VERSION=$(DUBBD_K3D_VERSION) --set IDAM_VERSION=$(IDAM_VERSION) --confirm

# Deploy the CI upgrade test for published SSO image
deploy/ci-upgrade-sso-published:
	cd test/ci-upgrade-sso && uds bundle deploy uds-bundle-uds-sso-*.tar.zst --confirm

# Deploy the CI upgrade test for source SSO image
deploy/ci-upgrade-sso-source:
	cd test/ci-upgrade-sso/source-sso && uds bundle deploy uds-bundle-uds-sso-*.tar.zst --confirm
