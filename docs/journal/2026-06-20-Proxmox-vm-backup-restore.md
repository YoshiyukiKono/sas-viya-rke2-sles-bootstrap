# 2026-06-20 Proxmox間でのSLES Template移植検証

## 背景

SAS Viya検証環境では、最終的に pve19 単体で環境を成立させたい。

そのため、node12 上で作成した SLES 15 SP7 Cloud-Init Template を pve19 へ移植できることを確認する。

対象テンプレート:

```text
VMID: 9007
Name : sles15sp7-template
```

本テンプレートには以下を含む。

* SLES 15 SP7 Cloud Image
* Cloud-Init
* SUSE登録済み
* PackageHub有効化
* vim
* jq
* git-core
* SSH鍵

---

## 最初の発想

当初は、

* node12
* pve19

それぞれで個別にテンプレートを作成することも考えた。

しかし、

* OS登録
* PackageHub設定
* ツール導入
* SSH鍵設定

を毎回実施するのは非効率である。

そのため、

「完成済みテンプレートを複製する」

方針を採用した。

---

## Backup作成

node12 上のテンプレートをバックアップ。

対象:

```text
VM 9007
```

保存先:

```text
stor4b
```

バックアップモード:

```text
Snapshot
```

バックアップは正常終了した。

---

## pve19へのRestore

バックアップを選択し Restore を実施。

初回実行時に以下のエラーが発生。

```text
TASK ERROR:
Content type 'images'
is not available on storage 'local'
```

---

## 原因調査

pve19 の Storage 設定を確認。

Datacenter
→ Storage
→ local

Content設定が以下となっていた。

```text
Backup
ISO image
Container template
```

Disk image が有効化されていなかった。

RestoreはVMディスクを生成するため、

```text
Disk image
```

が必須である。

---

## Storage設定変更

pve19 の local Storage に以下を追加。

```text
Disk image
Import
ISO image
Container template
Backup
```

Import も将来利用する可能性を考慮して有効化した。

---

## Restore失敗後の状態

Restore失敗後、

```text
VM 9007
```

が生成されていた。

しかし実体はほぼ空で、

* Memory 512MB
* CPU 1core

のみを持つ不完全なVMであった。

ディスクは作成されていない。

そのため削除して問題ないと判断。

---

## 再Restore

Storage設定修正後、

再度 Restore を実施。

今度は正常終了。

---

## 確認事項

移植後も、

* Cloud-Init Drive
* Template属性

が保持されることを確認。

つまり、

```text
Backup
↓
Restore
```

のみでテンプレートを別Proxmoxへ移送可能である。

---

## 得られた知見

Cloud-Initテンプレートは、

```text
Template
→ Backup
→ Restore
```

で容易に別ノードへ複製できる。

今後、

* NFS
* Jump Host
* RKE2
* Viya

用テンプレートを整備する場合も、

同じ方法で再利用できる。

---

## 今後

pve19 を単独で運用可能な構成とする。

予定IP:

```text
189 Jump Host
190 NFS
191 K8S ControlPlane #1
192 Viya ControlPlane
193 Viya Compute
194 Existing CT
195 Viya Default
196 Viya CAS
197 Viya Stateful
198 Viya Stateless
```

次の作業は、

Cloud-Init Template から

```text
VM189 (Jump Host)
```

を基点として、

各VMを順次展開する。
