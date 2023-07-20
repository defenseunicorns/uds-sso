.PHONY: k3d sso test

cluster:
	k3d cluster delete -c k3d/k3d.yaml
	k3d cluster create -c k3d/k3d.yaml
	zarf init --components=git-server --confirm

k3d:
	cd k3d && zarf package create --tmpdir=/tmp --architecture amd64 --confirm
	cd k3d && zarf package deploy --tmpdir=/tmp --confirm zarf-package-k3d-dubbd-base-amd64-0.1.tar.zst

sso:
	cd sso && zarf-git package create --tmpdir=/tmp --architecture amd64 --confirm
	cd sso && zarf-git package deploy -ltrace --tmpdir=/tmp --confirm zarf-package-uds-sso-amd64-0.1.tar.zst

remove:
	cd sso && zarf-git package remove -ltrace --tmpdir=/tmp --confirm zarf-package-uds-sso-amd64-0.1.tar.zst

new: cluster k3d sso

test:
	cd test-mission-app && zarf-git package create --tmpdir=/tmp --architecture amd64 --confirm
	cd test-mission-app && zarf-git package deploy -ltrace --tmpdir=/tmp --confirm zarf-package-podinfo-amd64-0.1.tar.zst

testclean:
	cd test-mission-app && zarf-git package remove zarf-package-podinfo-amd64-0.1.tar.zst --confirm
