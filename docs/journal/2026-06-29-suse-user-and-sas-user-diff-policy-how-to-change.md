# Jump Host における `suse` ユーザーと `sas` ユーザーの sudo 挙動の違い

Date: 2026-06-29

## 背景

SAS Viya 導入担当者向けに `sas` ユーザーを作成した。

```bash
sudo useradd -m -s /bin/bash sas
sudo usermod -aG wheel sas
```

`wheel` グループへ追加したため、Ubuntu 等と同様に sudo が利用できると考えていた。

しかし実際には `suse` と `sas` で sudo の挙動が異なることに気付いた。

---

## 現象

### suse

```bash
sudo -k
sudo whoami
```

結果

```text
root
```

パスワード入力は要求されない。

---

### sas

```bash
sudo whoami
```

結果

```text
[sudo] password for root:
```

root パスワードを要求される。

root パスワードを入力すると

```text
root
```

となる。

---

## 調査

### sas の所属グループ

```bash
id
```

結果

```text
uid=1002(sas)
groups=sas,docker,wheel
```

wheel グループへ正しく追加されている。

---

### sudo ポリシー

```bash
sudo grep targetpw /etc/sudoers
```

結果

```text
Defaults targetpw
```

SLES ではデフォルトで

```text
targetpw
```

が有効になっている。

これは

```text
sudo実行時に
実行ユーザーではなく
対象ユーザー(root)
のパスワードを要求する
```

という意味である。

---

### suse の sudo 権限

```bash
sudo -l
```

結果

```text
User suse may run the following commands:

(ALL) ALL
(ALL) NOPASSWD: ALL
```

ここで

```text
NOPASSWD: ALL
```

が付与されていることを確認した。

---

## 原因

Jump Host 構築時に作成した最初のユーザー `suse` は、SLES インストール時に管理者ユーザーとして登録されている。

そのため

```text
NOPASSWD: ALL
```

が付与されている。

一方、新たに作成した `sas` は

```text
wheel
```

グループには所属しているが、

```text
Defaults targetpw
```

の影響を受けるため、

sudo 実行時には root パスワードが必要となる。

整理すると以下となる。

| User | sudo | 認証方法 |
|------|------|----------|
| suse | ○ | パスワード不要 (NOPASSWD) |
| sas | ○ | root パスワード |

---

## 今回の運用方針

Jump Host の役割を以下とした。

| User | 用途 |
|------|------|
| suse | Kubernetes / RKE2 基盤管理 |
| sas | SAS Viya 導入担当 |

SAS 担当者は通常、

- kubectl
- helm
- git
- docker
- kustomize

などを利用する。

これらは sudo 権限を必要としない。

OS 設定変更が必要な場合は、基盤管理者 (`suse`) が対応する。

そのため、現時点では `sas` に NOPASSWD を付与せず、この構成を維持することとした。

---

## 将来変更する場合

### 方法1（推奨）

`visudo` を利用して個別設定を追加する。

```bash
sudo visudo
```

追加例

```text
sas ALL=(ALL) NOPASSWD: ALL
```

これにより 

```bash
sudo command
```

をパスワード無しで実行できる。

---

### 方法2

`targetpw` を無効化する。

```text
Defaults !targetpw
```

これにより

```text
root パスワード
```

ではなく

```text
sas のパスワード
```

で sudo 認証を行うようになる。

ただしこれはシステム全体の sudo ポリシーを変更するため、PoC 以外では慎重に検討する。

---

## 学び

Ubuntu 系 Linux では

```text
sudo
→ 自分のパスワード
```

が一般的である。

一方、SLES ではデフォルトで

```text
Defaults targetpw
```

が設定されているため、

```text
sudo
→ root パスワード
```

となる。

さらに、SLES インストール時に作成した初期管理者ユーザーには

```text
NOPASSWD: ALL
```

が付与されるため、新規作成ユーザーとは sudo の挙動が異なることを確認した。

この違いを理解しておくことで、今後 SLES 上でユーザー追加や権限設計を行う際の混乱を避けられる。

# 付録 sudu実行時のパスワードは誰のパスワードか？

Ubuntu を含め、多くの Linux が「自分のパスワード」を採用しています。それには理由があります。

## Ubuntu のデフォルトは自分のパスワード

例えば Ubuntu では、

```bash
sudo whoami
```

とすると

```text
[sudo] password for yoshiyuki:
```

のように、**実行ユーザーのパスワード**を聞かれます。

root パスワードは通常設定されておらず（ロックされていることが多い）、sudo による管理が前提です。

---

## なぜ自分のパスワードなのか

一番の目的は、

> **「今操作している本人であること」の確認**

です。

例えば、

```bash
rm -rf /
```

を実行しようとしたとき、

パスワードを要求されることで、

* キーボードを離席中に他人が操作する
* ターミナルを開きっぱなしにしていた
* 誤って危険なコマンドを実行した

といった事故を減らせます。

だから「実行前確認」の意味もありますが、本質は**本人認証**です。

---

## なぜ root パスワードではないのか

Ubuntu系の考え方は、

```text
管理者権限を持つ人
＝sudoグループに所属する人
```

です。

つまり、

```text
Alice
Bob
Charlie
```

全員が sudo 権限を持っていても、

それぞれ

```
Aliceのパスワード
Bobのパスワード
Charlieのパスワード
```

で認証できます。

もし root パスワード方式だと、

```text
rootのパスワード
```

を全員で共有することになります。

すると、

* 誰が実行したか分かりにくい
* root パスワードを変更すると全員へ周知が必要
* 退職者が出たら root パスワード変更が必要

という運用上の問題が生じます。

---

## では SLES の `targetpw` は何を狙っているのか

SLES のデフォルトは、

```text
root のパスワードを知っている人だけが本当の管理者
```

という思想です。

つまり、

```text
wheel
```

に入っていても、

```
rootパスワード
```

を知らなければ管理操作はできません。

これは、

> **root パスワードを知っている人だけに最終的な権限を集中させる**

という、より保守的な運用を意識した設計と言えます。

---

## 今回のPoCではどう考えるか

今回のように

* `suse`：基盤管理者
* `sas`：SAS導入担当

という役割分担なら、

SLES のデフォルト設定は理にかなっています。

`sas` は `wheel` に入っていても、root パスワードを知らない限り OS を変更できません。一方で、`kubectl` や `helm` など日常の Kubernetes 操作は sudo を使わずに実行できます。

---

実はこの違いは、**「誰を管理者と考えるか」**という設計思想の違いでもあります。

* **Ubuntu**: 「sudo 権限を持つ各ユーザー」が管理者。
* **SLES（`targetpw` 有効時）**: 「root」が唯一の管理者で、他のユーザーは root の代理として操作する。

どちらが優れているというより、運用ポリシーの違いがデフォルト設定に表れている、と考えるのがよいでしょう。

