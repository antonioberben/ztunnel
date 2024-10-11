## After long time

```bash
curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-darwin-arm64" && sudo install -c -m 0755 devpod /usr/local/bin && rm -f devpod
```

update the provider

```bash
devpod provider update kubernetes kubernetes
```

Version deployed and version of source code matters. Make sure they match. Pull the latest version of the source code. And copy the devcontainer.json file to the source code. Or you can use the latest version of `gcr.io/istio-testing/build-tools` image.

Make sure you hve a fresh installation of Istio:

```bash
istioctl uninstall --purge -y

istioctl install -y --set profile=ambient --set meshConfig.accessLogFile=/dev/stdout
```

Also, if you want to start from scratch, better you delete the devpod:

```bash
devpod delete . --force
```

Let's deploy an app to test ambient:

```bash
kubectl create ns my-ambient
kubectl label namespace my-ambient istio.io/dataplane-mode=ambient --overwrite
kubectl apply -f sleep.yaml -n my-ambient
kubectl apply -f helloworld.yaml -n my-ambient
```

Verify that app was included to Ambient mode:

```bash
kubectl -n istio-system logs -l k8s-app=istio-cni-node
```

Send traffic to the app:

```bash
kubectl -n my-ambient exec deploy/sleep -- sh -c 'for i in $(seq 1 100); do curl -s -I http://helloworld:5000/hello; done'
```

Output:

```text
HTTP/1.1 200 OK
Server: gunicorn
Date: Tue, 23 Jul 2024 14:21:03 GMT
Connection: keep-alive
Content-Type: text/html; charset=utf-8
Content-Length: 60
```

Verify that the logs are being written to the stdout:

```bash
kubectl -n istio-system logs -l app=ztunnel
```

Output:

```text
2024-07-23T14:21:03.450051Z	info	access	connection complete	src.addr=10.12.0.8:37522 src.workload=sleep-bc9998558-bhv5z src.namespace=my-ambient src.identity="spiffe://cluster.local/ns/my-ambient/sa/sleep" dst.addr=10.12.0.9:15008 dst.hbone_addr=10.12.0.9:5000 dst.service=helloworld.my-ambient.svc.cluster.local dst.workload=helloworld-v1-77489ccb5f-pjbq5 dst.namespace=my-ambient dst.identity="spiffe://cluster.local/ns/my-ambient/sa/default" direction="outbound" bytes_sent=84 bytes_recv=158 duration="118ms"
```

Now traffic works, make sure that the ztunnel is not dpeoyed so we can depoy our devpod-ztunnel:

```bash
kubectl patch daemonset -n istio-system ztunnel --type=merge -p='{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"ztunnel","operator":"In","values":["no"]}]}]}}}}}}}'
```

You should see that the ztunnel is not deployed anymore. To revert:

```bash
# RUN THIS ONLY TO REVERT THE PREVIOUS COMMAND
kubectl patch daemonset -n istio-system ztunnel --type=merge -p='{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"ztunnel","operator":"NotIn","values":["no"]}]}]}}}}}}}'
```

Make sure you have docker installed:

```bash
docker --version
```

Go to the root of the project and run the devpod:

Notice that using Kind cluster, the `STORAGE_CLASS` is `standard`. If you are using a different cluster, you may need to change it (i.e in EKS it would be `gp2`)
```bash
pushd /Users/antonio/projects/solo/ztunnel
  devpod up . --provider-option STORAGE_CLASS=gp2 --provider-option KUBECTL_PATH=/usr/local/bin/kubectl --provider-option KUBERNETES_NAMESPACE=istio-system --provider-option POD_MANIFEST_TEMPLATE=/Users/antonio/projects/solo/ztunnel/devpod/pod_manifest.yaml --devcontainer-path devpod/devcontainer.json --ide vscode --debug \
  --recreate --reset
popd
```

Notice that DevPod copies all files in this folder to the container. Make sure that the `out` folder is deleted before starting devpod. That folder is usully too heavy.

What is happening:
1. A busybox is created and the final devpod pod is deployed. This pod is based on 2 conttainers:
    1. Init container: ghcr.io/loft-sh/dockerless:0.1.4
    1. devpod container: ghcr.io/loft-sh/dockerless:0.1.4
1. We are pushing the current directory to the stack to create a workspace in the container




## More details

"image": "gcr.io/istio-testing/build-tools:master-8fb9ce88f6ad4cdd35c1660cd0ad0ab67eff4c6c",
"image":"mcr.microsoft.com/devcontainers/base:ubuntu"

kubectl apply -f k8s/service.yaml
devpod up . --provider-option STORAGE_CLASS=standard --provider-option KUBECTL_PATH=/usr/local/bin/kubectl --provider-option KUBERNETES_NAMESPACE=istio-system --provider-option POD_MANIFEST_TEMPLATE=/Users/antonio/projects/solo/ztunnel/devpod/pod_manifest.yaml --devcontainer-path devpod/devcontainer.json --ide vscode --debug \
--recreate --reset

rsync -rlptzv --progress --delete --exclude=.git --exclude=out "ztunnel.devpod:/workspaces/ztunnel" .

devpod delete . --force

kubectl patch daemonset -n istio-system ztunnel --type=merge -p='{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"ztunnel","operator":"In","values":["no"]}]}]}}}}}}}'

kubectl patch daemonset -n istio-system ztunnel --type=merge -p='{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"ztunnel","operator":"NotIn","values":["no"]}]}]}}}}}}}'

devpod provider add ../provider.yaml

devpod provider delete gloo-platform 

devpod provider update kubernetes kubernetes


Install the devpod CLI
```
curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-darwin-amd64" && sudo install -c -m 0755 devpod /usr/local/bin && rm -f devpod
```









# Issues

- Make sure that docker socket is at /var/run/docker.sock or there is a simlink pointing to the right one. For mac and docker desktop, you can change it at Settings -> Advanced -> Allow the default Docker socket to be used and press Apply & restart

- In config or by cli, you need to define the full path to Kubectl

- To attach devcontainer to a running pod: https://code.visualstudio.com/docs/devcontainers/attach-container

- In template, `name` for the pod is ignored

- In template, `app: ztunnel` label makes devpod to fail. If you add `app: ztunnel2`, it does not

- rsync files from remote to local: `rsync -rlptzv --progress --delete --exclude=.git --exclude=out "ztunnel.devpod:/workspaces/ztunnel" .`

- Extension are not installed in the devcontainer. You need to install them manually. No clue why.

- Build ztunnel image. 
```
In istio repo with ztunnel checked out at ../ztunnel you can do `BUILD_ZTUNNEL=1 BUILD_WITH_CONTAINER=0 make init && ./tools/docker --targets=ztunnel --hub localhost:5000 --tag sometag --push`
```
export GIT_TRACE_PACKET=1
export GIT_TRACE=1e
export GIT_CURL_VERBOSE=1

buildah build -f ./devpod/Dockerfile  --build-arg="TARGETARCH=out/rust/debug" -t my-ztunnel .