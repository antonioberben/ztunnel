export CLUSTER1=eu-central-1


kubectl --context="${CLUSTER1}" create namespace istio-system 

istioctl install --context="${CLUSTER1}" -y -f cluster1-iop.yaml

kubectl create --context="${CLUSTER1}" namespace sample

kubectl label --context="${CLUSTER1}" namespace sample istio.io/dataplane-mode=ambient

kubectl apply --context="${CLUSTER1}" -f helloworld.yaml -l service=helloworld -n sample

kubectl apply --context="${CLUSTER1}" -f helloworld.yaml -l version=v1 -n sample

kubectl apply --context="${CLUSTER1}" -f sleep.yaml -n sample


kubectl rollout restart deployment -n istio-system --context $CLUSTER1
kubectl rollout restart ds -n istio-system --context $CLUSTER1


kubectl rollout restart deployment -n sample --context $CLUSTER1
