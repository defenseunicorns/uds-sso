# Defense Unicorns UDS Single Sign On (SSO)

Pre-built Zarf Package to support Single Sign On with a [DUBBD](https://github.com/defenseunicorns/uds-package-dubbd)  deployment.

## Prerequisites

- Zarf is installed locally with a minimum version of [v0.28.3](https://github.com/defenseunicorns/zarf/releases/tag/v0.28.3)
- Optional: A working Kubernetes cluster on v1.26+ -- e.g k3d, k3s, KinD, etc (Zarf can be used to deploy a built-in k3s distribution)
- Working kube context (`kubectl get nodes` <-- meaning this command works)


## Getting Started

- Create a new k3d cluster with the following:
  - Initialize Zarf
  - Deploy Metallb - load balancer
  - Deploy DUBBD
  - Deploy UDS-IDAM
  - Deploy UDS-SSO
  - Deploy an example mission application to be protected by SSO


```bash
make cluster/full
```

For further information about UDS-SSO `make` targets view the [Makefile here](Makefile#L12).

#### Example Mission Application Configuration

During the `make cluster/full` make target execution there is a [step for deploying](Makefile#L50) and configuring an example mission app to be protected by SSO.

The [test-mission-app](dev/test-mission-app/podinfo/) deploys a podinfo app that has been configured with a [secret](dev/test-mission-app/podinfo/create-client-secret.yaml) that is used to create and configure the client for this app in keycloak. 

#### Creating Client Secret

To get start this [kubernetes Command](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret) created this [secret](dev/test-mission-app/podinfo/create-client-secret.yaml):

```bash
kubectl create secret generic create-client-secret \
  --namespace=podinfo
  --from-literal=id=dev_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_podinfo \
  --from-literal=name=podinfo \
  --from-literal=realm=baby-yoda \
  --from-literal=domain=bigbang.dev \
  --dry-run=client \
  -o yaml
```

>[!IMPORTANT]  
>This does not create the label that is required for this process to be successful. Make sure and add this label:
>
>```yaml
>pepr.dev/keycloak: createclient
>```
>This secret is used by PEPR to know how to configure Keycloak and SSO to protect the mission application.

>[!NOTE]  
>In some environments a `creationTimestamp: null` metadata tag is created and can cause some issues.

## Zarf Variables Configuration

| Name| Description| Default| Type| Notes|
|-----|------------|--------|-----|------|
|[REALM](sso/zarf.yaml#L13)|Realm name to deploy SSO too|baby-yoda|String||
|[AUTHSERVICE_VALUES](sso/zarf.yaml#L16)|SSO Authservice chart values file path|[values-authservice.yaml](sso/values-authservice.yaml)|File||
|[AUTHSERVICE_DEPENDS_ON](sso/zarf.yaml#L21)|SSO Authservice dependencies|"[]"|List||
|[AUTHSERVICE_CREATE_NAMESPACE](sso/zarf.yaml#L23)|Create SSO Authservice namespace|"true"|Boolean||
|[KEYCLOAK_BASE_DOMAIN](sso/zarf.yaml#L25)|Base domain name of keycloak|"keycloak.bigbang.dev"|String||
|[KEYCLOAK_REALM](sso/zarf.yaml#L27)|Realm name where keycloak is found|"baby-yoda"|String||
|[CA_FILE](sso/zarf.yaml#L29)|SSO Authservice Secret File|[ca.pem](sso/ca.pem)|File||

### Creating releases

[The pipeline](.github/workflows/tag-and-release.yml) uses [release-please-action](https://github.com/google-github-actions/release-please-action) for versioning and releasing OCI packages. This will automatically update `metadata.version` field in zarf.yaml to the same version number that is used for the release tag. To make this work, the `version` field must be [surrounded by Release Please's annotations](sso/zarf.yaml#L7),

```yaml
  # x-release-please-start-version
  version: "0.2.1"
  # x-release-please-end
```



More information on this can be found in [Release Please's documentation](https://github.com/googleapis/release-please/blob/main/docs/customizing.md#updating-arbitrary-files).

### How should I write my commits?

Before commiting it is recommended to run tests. Use the make target: `make test/idam` to run the smoke tests.

Release Please assumes you are using [Conventional Commit messages](https://www.conventionalcommits.org/).

The most important prefixes you should have in mind are:

- `fix:` which represents bug fixes, and correlates to a [SemVer](https://semver.org/)
  patch.
- `feat:` which represents a new feature, and correlates to a SemVer minor.
- `feat!:`,  or `fix!:`, `refactor!:`, etc., which represent a breaking change
  (indicated by the `!`) and will result in a SemVer major.

When the change is merged to the trunk, Release Please will calculate what changes are included and will create another PR to increase the version and tag a new release. This will also automatically generate a new set of packages in the OCI registry.