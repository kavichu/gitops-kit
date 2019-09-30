# Create eks cluster
```sh
eksctl create cluster -f cluster.yaml
```

# Clone the repo
```sh
export GHUSER=kavichu
git clone https://github.com/${GHUSER}/gitops-helm-workshop

cd gitops-helm-workshop
git config user.name "${GHUSER}"
git config user.email "luis@valdes.com.br"
```

# Helm v3
```sh
helmv3 repo add fluxcd https://charts.fluxcd.io

kubectl create ns fluxcd

helmv3 upgrade -i flux fluxcd/flux --wait \
       --namespace fluxcd \
       --set registry.pollInterval=1m \
       --set git.pollInterval=1m \
       --set git.url=git@github.com:${GHUSER}/gitops-helm-workshop
```


# Flux
```sh
curl -sL https://fluxcd.io/install | sh
export PATH=$PATH:$HOME/.fluxcd/bin

export FLUX_FORWARD_NAMESPACE=fluxcd

fluxctl identity
```


# Helm Operator
```sh
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/helm-v3-dev/deploy/flux-helm-release-crd.yaml

kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/flux-helm-release-crd.yaml

helmv3 upgrade -i helm-operator fluxcd/helm-operator --wait \
       --namespace fluxcd \
       --set git.ssh.secretName=flux-git-deploy \
       --set git.pollInterval=1m \
       --set chartsSyncInterval=1m \
       --set configureRepositories.enable=true \
       --set configureRepositories.repositories[0].name=stable \
       --set configureRepositories.repositories[0].url=https://kubernetes-charts.storage.googleapis.com \
       --set extraEnvs[0].name=HELM_VERSION \
       --set extraEnvs[0].value=v3 \
       --set image.repository=docker.io/fluxcd/helm-operator-prerelease \
       --set image.tag=helm-v3-5fa9fd3a

helm-v3-71bc9d62

helmv3 upgrade -i helm-operator fluxcd/helm-operator \
       --wait --namespace fluxcd \
       -f values.yaml
```


# Linkerd
```sh
curl -sL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

linkerd install | kubectl apply -f -

linkerd check
```


# Flagger
```sh
helmv3 repo add flagger https://flagger.app

kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml

helmv3 uninstall flagger

helmv3 upgrade -i flagger flagger/flagger --wait \
       --namespace linkerd \
       --set crd.create=false \
       --set metricsServer=http://linkerd-prometheus:9090 \
       --set meshProvider=linkerd
```


# Install kubeseal
```sh
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.8.1/kubeseal-darwin-amd64
sudo install -m 755 kubeseal-darwin-amd64 /usr/local/bin/kubeseal
```


## Use kubeseal
```sh
kubeseal --fetch-cert \
         --controller-namespace=fluxcd \
         --controller-name=sealed-secrets \
         > pub-cert.pem

kubectl -n prod create secret generic basic-auth \
        --from-literal=user=admin \
        --from-literal=password=admin \
        --dry-run \
        -o json > basic-auth.json

kubeseal --format=yaml --cert=pub-cert.pem < basic-auth.json > basic-auth.yaml
```

## Restore kube-seal
```sh
kubectl -n fluxcd get secret sealed-secrets-key8jzlg -o yaml \
        --export > sealed-secrets-key.yaml

kubectl replace secret -n fluxcd sealed-secrets-key -f sealed-secrets-key.yaml
kubectl delete pod -n fluxcd -l app=sealed-secrets
```
