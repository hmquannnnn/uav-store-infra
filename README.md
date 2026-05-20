# uav-store-infra

GitOps and infrastructure workspace for UAV Store.

## Layout

```text
deployment/k8s/      Raw Kubernetes manifests watched by ArgoCD
argocd/              ArgoCD Application definitions
examples/            Example manifests that must not be synced directly
jenkins/             Local Jenkins compose/config
terraform/           Future cloud infrastructure code
```

ArgoCD should point to:

```text
repoURL: https://github.com/hmquannnnn/uav-store-infra.git
targetRevision: dev
path: deployment/k8s
```

Backend and frontend Jenkins jobs build images, push them to DockerHub, then update image tags in `deployment/k8s`.

Do not commit `deployment/k8s/01-secrets.yaml` to a public repository. Create the Kubernetes Secret manually for now, or replace it with Sealed Secrets / External Secrets later.
