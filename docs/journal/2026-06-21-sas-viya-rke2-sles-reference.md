以下の内容で、前回のジャーナル（RKE2構築準備開始時点）以降の作業記録として残せると思います。

---

# Journal: SAS Viya RKE2 on SLES - VM準備とNFS構成

**Date:** 2026-06-21
**Project:** sas-viya-rke2-sles-reference

## 概要

SAS Viya検証用RKE2クラスタ構築に向けて、SLES 15 SP7テンプレートからVM群を作成し、OS登録、基本設定、NFS共有の準備まで完了した。

本日の成果として、

* 全VM作成
* ネットワーク設定
* SSH疎通確認
* SLES登録
* 共通設定
* ホスト名設定
* firewalld無効化
* NFS Server構築
* NFS Client設定
* NFS共有への全ノードからの書き込み確認

まで完了した。

---

# 構成

## Inventory

```csv
hostname,ip,role
rancher,10.110.0.187,rancher
jump-host,10.110.0.189,jump
nfs,10.110.0.190,nfs
rke2-control-plane,10.110.0.191,rke2-control-plane
viya-control,10.110.0.192,viya-control
viya-compute,10.110.0.193,viya-compute
viya-default,10.110.0.195,viya-default
viya-cas,10.110.0.196,viya-cas
viya-stateful,10.110.0.197,viya-stateful
viya-stateless,10.110.0.198,viya-stateless
```

## RKE2構成

| Node | Role          |
| ---- | ------------- |
| 191  | Control Plane |
| 192  | Worker        |
| 193  | Worker        |
| 195  | Worker        |
| 196  | Worker        |
| 197  | Worker        |
| 198  | Worker        |

---

# テンプレート問題の発見

当初利用していたGolden Templateに以下の問題を発見。

## 症状

```bash
df -h
```

結果:

```text
/dev/sdb3 1006M 88%
```

Root領域が1GBしか存在しない。

一方で

```bash
lsblk
```

では

```text
sda 32G
sdb 1.5G
```

が存在していた。

---

## 原因

cloud-initテンプレート作成時に

```text
sdb
```

がブートディスクになっていた。

本来利用したかった

```text
sda
```

は未使用状態になっていた。

---

## 対応

### 1. sdaを30GBへ拡張

Proxmox GUIより

```text
Hardware
→ scsi0
→ Resize Disk
```

実施。

### 2. Boot Order変更

```text
scsi0
```

を先頭へ変更。

### 3. 再起動

起動後

```bash
df -h
```

結果

```text
/dev/sda3 31G 5%
```

となり正常化。

### 4. Unused Disk削除

旧scsi1をDetach後、

```text
Unused Disk
```

として残ったため削除。

---

# VM検証

NodeReportにより確認。

結果:

```text
ssh=OK
hostname_match=OK
root_fs=31G
```

全VM正常。

---

# SLES登録

PowerShell版

```powershell
Register-SLES.ps1
```

を作成。

当初失敗したが、

```powershell
ssh suse@host "sudo SUSEConnect -r REGCODE"
```

で動作確認。

ログ出力強化後、

```powershell
Register-SLES.ps1
```

成功。

---

# Common Setup

PowerShell版

```powershell
Common-Setup.ps1
```

作成。

実施内容:

* package update
* 基本ユーティリティ導入
* ssh設定確認

全ノード成功。

---

# Hostname設定

PowerShell版

```powershell
Set-Hostname.ps1
```

実施。

Inventoryに合わせて

```text
rancher
jump-host
nfs
rke2-control-plane
...
```

へ変更。

---

# Firewall

方針:

```text
検証環境
RKE2構築優先
```

のため

```text
firewalld無効
```

採用。

実施:

```powershell
Disable-Firewalld.ps1
```

成功。

---

# NFS Server構築

対象:

```text
10.110.0.190
```

共有ディレクトリ:

```text
/srv/nfs/viya
```

---

## 問題

スクリプト上では成功していたが、

```bash
cat /etc/exports
```

結果:

```text
(empty)
```

であった。

つまり

```text
NFSサービス起動済
Export未設定
```

状態だった。

---

## 手動修正

```bash
echo '/srv/nfs/viya 10.110.0.0/24(rw,sync,no_subtree_check,no_root_squash)' \
| sudo tee /etc/exports

sudo exportfs -ra
sudo exportfs -v
```

結果:

```text
/srv/nfs/viya 10.110.0.0/24(...)
```

確認。

---

# NFS Client構築

対象:

```text
191
192
193
195
196
197
198
```

マウントポイント:

```text
/mnt/viya-nfs
```

---

## 初期問題

```text
showmount: command not found
```

発生。

showmountチェックをスキップするよう修正。

---

## 次の問題

```text
mount.nfs: access denied by server
```

発生。

原因:

```text
/etc/exports未設定
```

であった。

---

## 修正後確認

```bash
mount | grep viya-nfs
```

結果:

```text
10.110.0.190:/srv/nfs/viya
on /mnt/viya-nfs
type nfs4
```

確認。

---

# RWX確認

各ノードから

```bash
echo hostname > /mnt/viya-nfs/test-*.txt
```

実施。

NFSサーバ上で確認:

```bash
ls -l /srv/nfs/viya
```

結果:

```text
test-rke2-control-plane.txt
test-viya-control.txt
test-viya-compute.txt
test-viya-default.txt
test-viya-cas.txt
test-viya-stateful.txt
test-viya-stateless.txt
```

全ノードからの書き込み成功。

---

# 現在の状態

完了:

* VM作成
* ネットワーク設定
* SSH確認
* SLES登録
* Common Setup
* Hostname設定
* firewalld無効化
* NFS Server構築
* NFS Client構築
* RWX確認

未着手:

* RKE2 Server構築
* RKE2 Agent参加
* kubectl設定
* Helm導入
* Rancher接続
* SAS Viyaデプロイ

---

# 次回作業

Jump Hostから作業を継続。

対象:

```text
10.110.0.191
```

実施予定:

```text
RKE2 Serverインストール
↓
Cluster Token取得
↓
Worker参加
↓
kubectl確認
↓
Helm導入
```

ここまでで、RKE2クラスタ構築準備は完了した。
