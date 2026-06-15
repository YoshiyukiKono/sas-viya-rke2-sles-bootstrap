# DNS and LoadBalancer Notes for SAS Viya

SAS Viya is normally accessed through Ingress using FQDNs. Plan DNS and LoadBalancer details before handing the cluster to the SAS owner.

## Recommended lab pattern

```text
viya.example.local       A      <Ingress LoadBalancer IP>
*.viya.example.local     CNAME  viya.example.local
```

If wildcard CNAME is not possible, create the specific hostnames requested by the SAS owner.

## LoadBalancer options

Possible implementations:

- MetalLB
- kube-vip
- external physical/virtual load balancer
- manually assigned external IPs for a lab

For Proxmox lab environments, MetalLB in L2 mode is often the simplest. Reserve a range outside DHCP, for example:

```text
192.168.10.220-192.168.10.240
```

## Handover values

Document:

- Ingress controller name
- IngressClass name
- LoadBalancer implementation
- LoadBalancer IP range
- Actual external IP assigned to the ingress controller
- Base domain
- Wildcard DNS status
