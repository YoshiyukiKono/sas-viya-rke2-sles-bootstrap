# Proxmox + SLES Cloud Image + Cloud-Init で Jump Host を構築

## 概要

SAS Viya PoC 環境構築に向けて、Proxmox VE 上に SLES 15 SP7 Cloud Image を利用した管理用 Jump Host を構築した。

目的は以下である。

* Kubernetes 管理用サーバ
* SSH 鍵管理
* kubectl / helm / git 実行環境
* Rancher および RKE2 管理端末

最終的な IP アドレス設計は以下とした。

| IP  | 用途                |
| --- | ----------------- |
| 187 | Rancher Manager   |
| 189 | Jump Host         |
| 190 | NFS               |
| 191 | K8S ControlPlane  |
| 192 | Viya ControlPlane |
| 193 | Viya Compute      |
| 194 | 既存 CT             |
| 195 | Viya Default      |
| 196 | Viya CAS          |
| 197 | Viya Stateful     |
| 198 | Viya Stateless    |

---

## テンプレート作成

事前に以下の記事で SLES Cloud Image テンプレートを作成済み。

* 2026-06-15-proxmox-sles-cloud-image-template.md

テンプレート VM ID:

```text
9007
```

---

## Jump Host 作成

テンプレートから Full Clone を作成。

設定:

```text
VM Name : VM2-mgmt-jump-host
IP      : 10.110.0.189/24
GW      : 10.110.0.1
User    : suse
```

Cloud-Init の設定変更後、

```text
Regenerate Image
```

を実行してから起動する。

---

## トラブルシュート

### 10.110.0.188 が利用できない

当初は以下を設定した。

```text
10.110.0.188
```

しかし Cloud-Init は成功するものの IPv4 が有効にならず、

```bash
wicked ifstatus eth0
```

では

```text
ipv4 static failed
```

となった。

調査の結果、

```powershell
arp -a | findstr 10.110.0.188
```

に応答があり、さらに VM 停止後も Ping 応答が継続した。

つまり、

```text
10.110.0.188 は既存機器が利用中
```

であることが判明。

Jump Host は

```text
10.110.0.189
```

へ変更した。

---

## SCC 登録

Cloud Image は未登録状態で起動する。

状態確認:

```bash
sudo SUSEConnect --status-text
```

結果:

```text
Not Registered
```

Subscription の Registration Code を利用し登録。

```bash
sudo SUSEConnect -r <Registration Code>
```

登録後、

```bash
sudo zypper refresh
```

が利用可能となった。

---

## PackageHub 有効化

Git 利用のため PackageHub を有効化。

```bash
sudo SUSEConnect -p PackageHub/15.7/x86_64
```

確認:

```bash
sudo SUSEConnect --list-extensions
```

---

## 基本ツール導入

```bash
sudo zypper install git-core
sudo zypper install jq
sudo zypper install vim
```

確認:

```bash
git --version
jq --version
vim --version
```

---

## SSH 鍵作成

Jump Host 上で管理用鍵を作成。

```bash
ssh-keygen -t ed25519 -C "suse-k8s-admin"
```

権限確認:

```text
~/.ssh            700
id_ed25519        600
id_ed25519.pub    644
authorized_keys   600
```

---

## 完了状態

以下が利用可能になった。

* SSH 接続
* SCC 登録
* PackageHub
* Git
* jq
* Vim
* 管理用 SSH 鍵

これにより Kubernetes 管理用 Jump Host が完成した。

次のステップは Rancher Manager VM (10.110.0.187) の構築である。
