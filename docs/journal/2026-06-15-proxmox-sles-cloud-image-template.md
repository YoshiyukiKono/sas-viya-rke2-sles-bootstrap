これはちょうど Research Fabric Lab の Journal に置くような内容ですね。

あなたの場合、単なる「手順書」よりも、

* なぜ Cloud Image を選んだのか
* Proxmox 9.0.3 の UI で何に迷ったか
* 実際にどう解決したか

を書いた方が後で自分も助かるし、Qiita的にも価値があります。

---

# Journal: Proxmox VE 9.0.3 で SLES 15 SP7 Cloud Image テンプレートを作成する

## 背景

SAS Viya 用 Kubernetes 基盤を構築するにあたり、まずは Proxmox VE 上で SLES 15 SP7 の VM を複数展開できる環境を準備することにした。

今回は通常の ISO インストールではなく、SUSE が提供する Cloud Image を利用し、将来的には Cloud-init による自動構成を前提としたテンプレート化を目指す。

利用したイメージは以下。

```text
SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

---

## Proxmox Storage 設定の確認

まず Storage を確認した。

今回の環境では以下の構成となっていた。

| Storage | 用途                    |
| ------- | --------------------- |
| local   | VM Disk, ISO, Import  |
| stor4b  | Proxmox Backup Server |

Datacenter → Storage を確認すると、

```text
local
  Content:
    Backup
    ISO image
    Container template
```

となっていた。

この状態では qcow2 を Import できない。

---

## local Storage に Import を追加

Datacenter → Storage → local → Edit

Content に

```text
Import
Disk image
```

を追加した。

追加後、

```text
local
 └ Import
```

メニューが利用可能になった。

---

## Cloud Image をアップロード

Storage → local → Import

から Windows 上に保存していた

```text
SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

をアップロードした。

アップロード後は次のように表示される。

```text
Import
 └ SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

---

## 「Import」だけでは VM は作られない

ここで最初に混乱した。

Import ボタンを押すと、

```text
Import Hard Disk
Target Guest
```

が表示される。

つまり、

```text
qcow2
↓
VM作成
```

ではなく、

```text
qcow2
↓
既存VMへディスク追加
```

という動作である。

---

## 空 VM を作成

まずテンプレート用 VM を作成した。

```text
VM ID: 9007
Name : sles15sp7-template
```

OS インストールメディアは指定しない。

```text
Do not use any media
```

を選択。

仮に 32GB ディスクを作成して VM を生成した。

---

## Cloud Image を Import

Storage → local → Import

Target Guest に

```text
9007 sles15sp7-template
```

を指定して Import を実施。

結果として Hardware に以下が現れた。

```text
scsi0 32GB
scsi1 1585MB
```

---

## 起動ディスクがどちらか分からない問題

この段階では

```text
scsi0
scsi1
```

のどちらが Cloud Image なのか判断できない。

Boot Order を確認すると、

```text
scsi0
ide2
net0
```

となっていた。

Import 後の Cloud Image は

```text
scsi1
```

であるため、

Boot Order を変更した。

```text
scsi1
scsi0
ide2
net0
```

---

## 起動確認

VM を起動すると、

```text
JeOS Firstboot
```

が表示された。

Cloud Image なので login プロンプトが出ることを予想していたが、実際には初回セットアップ画面が表示された。

---

## Firstboot を実施

設定内容は以下。

```text
Language : English (US)
Keyboard : English (US)
Timezone : Asia/Tokyo
```

Linux サーバ用途であり、SSH 利用を前提とするためキーボードは US 配列を選択した。

---

## Cloud-init の確認

ログイン後に確認。

```bash
cat /etc/os-release
```

結果。

```text
SUSE Linux Enterprise Server 15 SP7
```

Cloud-init も導入済みであった。

```bash
cloud-init --version
```

```text
cloud-init 23.3
```

サービス状態確認。

```bash
systemctl status cloud-init
```

結果。

```text
Loaded: loaded
Active: inactive (dead)
```

Cloud-init は常駐サービスではなく、起動時に実行して終了するため正常状態である。

---

## ここまでの成果

この時点で以下を確認できた。

* SLES 15 SP7 Cloud Image の Import 成功
* Proxmox 9.0.3 上で正常起動
* Cloud-init 導入済み
* テンプレート化可能な状態

---

## 次の作業

次は以下を実施予定。

### CloudInit Drive 追加

```text
Hardware
  ↓
Add
  ↓
CloudInit Drive
```

### Cloud-init 設定

```text
User
Password
SSH Public Key
Network
```

### テンプレート化

```text
Shutdown
  ↓
Convert to Template
```

### Kubernetes ノード展開

テンプレートから

```text
cp-01
cp-02
cp-03
worker-01
worker-02
worker-03
```

を Clone し、RKE2 クラスタ構築へ進む。

---

今回の学びは、

> Proxmox の Import は VM 作成機能ではなく、既存 VM へのディスク取り込み機能である

という点だった。

Cloud Image を使ったテンプレート作成は ISO インストールより大幅に効率的だが、最初は UI の挙動を理解するまで少し迷う部分があった。今後はこのテンプレートをベースに、SAS Viya 用 RKE2 クラスタの自動展開を進めていく。
