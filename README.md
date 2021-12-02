# Helm Image

Install helm chart in a cloud-native way

## Install clusternet-agent chart

Install with docker run

```console
docker run -it ccr.ccs.tencentyun.com/danielxxli/helm:3.7.1 https://danielxlee.github.io/clusternet-charts install clusternet-agent -n clusternet-system --set parentURL=https://172.11.33.44:6443 --set registrationToken=07401b.f395accd246ae52d --set extraArgs.cluster-reg-name=cls-xxxxxx --create-namespace helmrepo/clusternet-agent
```

Install with k8s job

```console
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: install-clusternet-agent
  namespace: clusternet-system
spec:
  ttlSecondsAfterFinished: 100
  template:
    spec:
      serviceAccountName: clusternet-app-deployer
      containers:
      - name: helm
        image: csighub.tencentyun.com/tdcc/helm:3.7.1
        args: ["https://danielxlee.github.io/clusternet-charts", "install", "clusternet-agent", "-n", "clusternet-system", "--set", "parentURL=https://hub-control-plane:6443", "--set", "registrationToken=07401b.f395accd246ae52d", "--set", "extraArgs.cluster-reg-name=cls-xxxxxx", "--create-namespace", "helmrepo/clusternet-agent"]
      restartPolicy: Never
  backoffLimit: 4
EOF
```

## 创建一个临时的 helm repo

创建 Repo

```shell
helm install chartmuseum -n kube-system \
  --set image.repository=ccr.ccs.tencentyun.com/danielxxli/chartmuseum \
  --set service.type=LoadBalancer \
  --set service.externalPort=8888 \
  --set env.open.DISABLE_API=false \
  chartmuseum/chartmuseum
```

获取 Repo 的地址

```shell
export SERVICE_IP=$(kubectl get svc --namespace kube-system chartmuseum -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo http://$SERVICE_IP:8888
```

Push Charts 到 Repo

```shell
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helm
  namespace: kube-system
  labels:
    app: helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helm
  template:
    metadata:
      labels:
        app: helm
    spec:
      containers:
      - name: helm
        image: ccr.ccs.tencentyun.com/danielxxli/helm:3.7.1
        command: ["/bin/sh", "-c"]
        args: ["sleep 3600"]
EOF

kubectl -n kube-system exec -it helm-6679966b68-56gnf -- sh

helm repo add helmrepo https://$SERVICE_IP:8888
helm push clusternet-hub-0.2.0.tgz helmrepo
helm push clusternet-agent-0.2.0.tgz helmrepo
helm push clusternet-syncer-0.2.0.tgz helmrepo
helm repo update
helm search repo helmrepo/
```
