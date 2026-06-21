kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

kubectl -n projectcontour patch svc envoy -p '{"spec":{"type":"NodePort"}}'
kubectl get svc -n projectcontour
