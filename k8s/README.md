# K8S + FluxCD

From https://github.com/niki-on-github/nixos-k3s

## setup flux

```shell
flux bootstrap git \
        --url=ssh://git@github.com/reonokiy/anso.git \
        --branch=main \
        --path=k8s/flux \
        --private-key-file=./private

flux create secret git flux-system-git-anso-secrets \
        --url=ssh://git@github.com/reonokiy/anso-secrets

cat tmp.key | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin
```