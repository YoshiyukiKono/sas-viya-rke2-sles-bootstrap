
# SAS Viya RKE2 Bootstrap on Proxmox

Date: 2026-06-21

## 概要

SAS Viya 検証環境向けに、Proxmox上のSLES VMを利用してRKE2クラスタを構築した。

当初はKubernetesクラスタ構築そのものを主目的としていたが、実際にはネットワークトラブルの切り分けに多くの時間を費やした。

結果として、

- RKE2
- NFS Dynamic Provisioning
- cert-manager
- Contour
- Rancher Manager

まで含めた、SAS Viya導入可能な状態のプラットフォームを完成させることができた。

---

## 最終構成

### 管理ノード

| Hostname | IP |
|-----------|-----------|
| rancher | 10.110.0.187 |
| jump-host | 10.110.0.189 |

### Kubernetes Cluster

| Hostname | IP |
|-----------|-----------|
| nfs | 10.110.0.190 |
| rke2-control-plane | 10.110.0.191 |
| viya-control | 10.110.0.192 |
| viya-compute | 10.110.0.193 |
| viya-default | 10.110.0.195 |
| viya-cas | 10.110.0.196 |
| viya-stateful | 10.110.0.197 |
| viya-stateless | 10.110.0.198 |

---

## ノードラベル

SAS Viya用として以下のラベルを割り当てた。

| Node | Label |
|--------|--------|
| viya-control | control |
| viya-compute | compute |
| viya-default | default |
| viya-cas | cas |
| viya-stateful | stateful |
| viya-stateless | stateless |

```bash
kubectl get nodes --show-labels
````

により確認。

---

## 最初の問題

クラスタ構築直後からPod通信が正常に機能しなかった。

症状は以下。

* CoreDNSがCrashLoop
* Metrics Serverが起動しない
* Snapshot Controllerが起動しない
* Rancher Importが失敗する
* Service IPへアクセスできない

例えば、

```bash
kubectl run netcheck --rm -it \
  --restart=Never \
  --image=curlimages/curl \
  -- sh -c 'curl -k https://10.43.0.1:443/version'
```

がタイムアウトする状態だった。

---

## 調査

### VXLAN確認

Control Plane上で確認。

```bash
sudo ss -lun | grep 8472
```

結果：

```text
0.0.0.0:8472 LISTEN
```

Flannel VXLAN自体は起動していた。

---

### tcpdump確認

```bash
sudo tcpdump -ni eth0 udp port 8472
```

VXLANパケットは送信されていることを確認。

しかし通信は成立していなかった。

---

### flannel.1確認

全ノードで確認。

```bash
ip -s link show flannel.1
```

結果：

```text
RX packets = 0
TX dropped > 0
```

全ノードで共通。

これは「VXLANパケットが送信されるが受信できていない」ことを意味する。

---

## 原因

原因は Kubernetes ではなかった。

Proxmox Firewall が VXLAN通信を阻害していた。

UDP 8472 が VM 間で通過できず、

Canal (Calico + Flannel) が Overlay Network を構築できていなかった。

---

## 解決

Proxmox側で Firewall を無効化。

その後、

* 全VM再起動
* RKE2再起動

を実施。

復旧後、

```bash
kubectl get pods -A
```

で以下が正常起動。

* CoreDNS
* Metrics Server
* Snapshot Controller

---

## NFS Dynamic Provisioning

NFSサーバ：

```text
10.110.0.190
```

インストール：

```text
nfs-subdir-external-provisioner
```

StorageClass：

```text
viya-nfs
```

PVC確認：

```bash
kubectl get pvc
```

結果：

```text
STATUS=Bound
```

RWX動作確認完了。

---

## cert-manager

Helmで導入。

```bash
kubectl get pods -n cert-manager
```

全PodがReadyとなった。

---

## Contour

当初、Bitnami版Contourを利用したが失敗。

エラー：

```text
ErrImagePull
docker.io/bitnami/contour
```

イメージが存在しなかった。

Project Contour公式Chartへ切り替え。

結果：

* contour Ready
* envoy Ready

となった。

---

## Rancher Manager

専用VM：

```text
10.110.0.187
```

上にK3sを構築。

その後、

* cert-manager
* Rancher 2.14

を導入。

---

## Rancher Import失敗

Import直後、

```text
cattle-cluster-agent
```

が起動しなかった。

ログ：

```text
Could not resolve host:
rancher.lab.local
```

---

## CoreDNS修正

CoreDNSへ hosts エントリを追加。

```text
hosts {
  10.110.0.187 rancher.lab.local
  fallthrough
}
```

確認：

```bash
kubectl run dns-test --rm -it \
  --restart=Never \
  --image=busybox:1.36 \
  -- nslookup rancher.lab.local
```

結果：

```text
10.110.0.187
```

名前解決成功。

---

## Rancher Import成功

その後、

```text
Cluster Status = Active
```

となり、

7ノード全てを Rancher から管理できるようになった。

---

## 完成状態

構築完了コンポーネント：

* RKE2
* Canal
* CoreDNS
* Metrics Server
* NFS Provisioner
* cert-manager
* Contour
* Rancher Manager

ノード数：

```text
7 Nodes
```

状態：

```text
Ready for SAS Viya Deployment
```

---

## 学び

今回最大の問題は Kubernetes ではなくネットワークだった。

CoreDNS、Metrics Server、PVC、Rancher Agentなどの障害はすべて結果であり、根本原因は Proxmox Firewall による VXLAN遮断だった。

今後、Proxmox上でRKE2を構築する際は、まず以下を確認する。

* UDP 8472
* flannel.1 RXカウンタ
* Proxmox VM Firewall設定

Kubernetes側のデバッグを始める前に、Overlay Networkが成立していることを確認するべきである。


