kubectl label node viya-control workload.sas.com/class=compute --overwrite
kubectl label node viya-compute workload.sas.com/class=compute --overwrite
kubectl label node viya-cas workload.sas.com/class=cas --overwrite
kubectl label node viya-stateful workload.sas.com/class=stateful --overwrite
kubectl label node viya-stateless workload.sas.com/class=stateless --overwrite
kubectl label node viya-default workload.sas.com/class=default --overwrite
