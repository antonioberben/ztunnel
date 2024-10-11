export MGMT=eu-central-1
export CLUSTER1=eu-central-1
export CLUSTER2=eu-central-1
export ISTIO_VERSION=1.21.0
export REVISION=1-21

echo "TEST1:"
for i in {1..10}
do
  echo "Hi $i"
  pod=$(kubectl get pod --context="${CLUSTER1}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')
  kubectl exec --context="${CLUSTER1}" -n sample -c sleep "$pod" -- curl -sS helloworld.sample.svc.cluster.local:5000/hello
done

