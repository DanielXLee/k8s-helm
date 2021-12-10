# Helm Image

Install helm chart in a cloud-native way

## Install clusternet-agent chart

Install with docker run

```console
docker run -it ccr.ccs.tencentyun.com/danielxxli/clusternet-agent-installer:v0.2.0 --version 0.2.0 --set parentURL=https://172.11.33.44:6443 --set registrationToken=07401b.f395accd246ae52d --set extraArgs.cluster-reg-name=cls-xxxxxx --repo https://danielxlee.github.io/clusternet-charts
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
        image: ccr.ccs.tencentyun.com/danielxxli/clusternet-agent-installer:v0.2.0
        args: ["--version", "0.2.0", "--set", "parentURL=https://169.254.128.158:60002", "--set", "registrationToken=6qfsz6.74qrwsgt2q8dlxn8", "--set", "extraArgs.cluster-reg-name=cls-g66qfsz6", "--repo", "https://danielxlee.github.io/clusternet-charts"]
      restartPolicy: Never
  backoffLimit: 4
EOF
```

## 创建一个临时的 Helm Repo, 并且把 charts 导入到 Repo 中

### 创建 Repo

```console
helm add repo chartmuseum https://chartmuseum.github.io/charts
helm repo update
helm pull chartmuseum/chartmuseum
helm install chartmuseum -n kube-system \
  --set image.repository=ccr.ccs.tencentyun.com/danielxxli/chartmuseum \
  --set service.type=LoadBalancer \
  --set service.externalPort=8888 \
  --set env.open.DISABLE_API=false \
  chartmuseum-3.4.0.tgz
```

### 获取 Repo 的地址

```console
SERVICE_IP=$(kubectl -n kube-system get svc chartmuseum -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo http://$SERVICE_IP:8888
export CHART_REPO_URL=http://$SERVICE_IP:8888
```

### Push Charts 到 Repo

```console
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: push-charts
  namespace: kube-system
  labels:
    app: push-charts
spec:
  replicas: 1
  selector:
    matchLabels:
      app: push-charts
  template:
    metadata:
      labels:
        app: push-charts
    spec:
      containers:
      - name: push-charts
        image: ccr.ccs.tencentyun.com/danielxxli/helm:latest
        env:
        - name: CHART_REPO_URL
          value: $CHART_REPO_URL
EOF
```

```console
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: push-charts
  namespace: kube-system
spec:
  ttlSecondsAfterFinished: 100
  template:
    spec:
      containers:
      - name: push-charts
        image: ccr.ccs.tencentyun.com/danielxxli/helm:latest
        env:
        - name: CHART_REPO_URL
          value: $CHART_REPO_URL
EOF
```
