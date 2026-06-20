# Journal: SLES15 SP7 Template SSH Access Troubleshooting

Date: 2026-06-20

## 背景

SLES15 SP7 Cloud Image から作成したテンプレート VM を利用し、Proxmox 上で Viya 用 VM 群を展開する準備を行った。

目標は以下。

* Cloud-Init による IP 設定
* SSH 公開鍵認証
* Windows からパスワードなしでログイン
* ジャンプホストから各 VM へ SSH 接続
* テンプレート化による再利用

---

## 1. Cloud-Init 適用後に IPv4 が設定されない

VM2-mgmt-jump-host を作成し、

```text
IP: 10.110.0.188/24
GW: 10.110.0.1
```

を Cloud-Init に設定した。

しかし起動後、

```bash
ip -4 a
```

では loopback のみ表示され、

```bash
ip route
```

も空だった。

一方で、

```bash
cloud-init status --long
```

では完了しているように見えた。

調査の結果、

```bash
sudo wicked show all
```

で

```text
eth0
device-not-running
leases: ipv4 static failed
```

となっていた。

---

## 2. IP重複の疑い

Cloud-Init 設定では

```text
10.110.0.188
```

を割り当てていた。

Windows から確認すると、

```powershell
ping 10.110.0.188
```

に応答があった。

さらに

```powershell
arp -a | findstr 10.110.0.188
```

で MAC アドレスが返ってきた。

そのため、

「Cloud-Init が失敗した」のではなく、

「別ホストが既に 10.110.0.188 を使用している」

可能性が高いと判断した。

後日確認すると、実際に別ホストが利用していた。

---

## 3. IP変更

管理用アドレス体系を見直し、

```text
187 Rancher
189 Jump Host
190 NFS
191 Kubernetes Control Plane
192 Viya Control Plane
193 Viya Compute
194 Existing CT
195 Viya Default
196 Viya CAS
197 Viya Stateful
198 Viya Stateless
```

へ変更。

ジャンプホストは

```text
10.110.0.189
```

を利用することにした。

Cloud-Init の IP 設定を修正し、

```text
ip=10.110.0.189/24,gw=10.110.0.1
```

を設定。

その後、

```text
Regenerate Image
```

を実行した。

起動後、

```bash
ip -4 a
ip route
```

で正常な IPv4 設定を確認。

---

## 4. SLES未登録問題

Cloud Image は未登録状態だった。

確認すると、

```bash
sudo SUSEConnect --status-text
```

で

```text
Not Registered
```

と表示された。

登録後、

```bash
sudo zypper refresh
```

は成功した。

しかし

```bash
sudo zypper install git
```

は失敗。

調査すると、

```bash
zypper search git
```

で

```text
git-core
```

として提供されていた。

結果として、

```bash
sudo zypper install git-core
```

で解決した。

また、

```bash
sudo SUSEConnect -p PackageHub/15.7/x86_64
```

で PackageHub も有効化した。

---

## 5. SSH鍵生成

ジャンプホスト上で

```bash
ssh-keygen -t ed25519
```

を実行。

生成された鍵：

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

権限は以下。

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## 6. Windows側への秘密鍵コピー失敗

当初、コンソールから手動コピーした。

しかし接続時に

```text
Load key ... invalid format
```

が発生。

原因はコピー時の改行欠落または文字欠損。

最終的に

```powershell
scp suse@10.110.0.189:/home/suse/.ssh/id_ed25519 `
    $HOME\.ssh\id_ed25519
```

で再取得し解決。

---

## 7. Cloud-Init User の罠

Cloud-Init の SSH 公開鍵設定は投入済みだった。

しかし、

```powershell
ssh suse@10.110.0.202
```

でパスワードを要求された。

調査すると、

Cloud-Init の

```text
User
```

が

```text
Default
```

になっていた。

つまり公開鍵は

```text
default
```

ユーザー向けに配置されており、

```text
suse
```

ユーザーには配置されていなかった。

Cloud-Init を

```text
User = suse
```

へ変更し、

```text
Regenerate Image
```

を実施。

以後、

```powershell
ssh suse@10.110.0.202
```

で公開鍵認証が利用されるようになった。

---

## 8. known_hosts 問題

VM再作成後、

```powershell
ssh suse@10.110.0.202
```

で

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED
```

が発生。

原因は SSH ホスト鍵が再生成されたため。

Windows 側で

```powershell
ssh-keygen -R 10.110.0.202
```

を実行し、

再接続時に

```text
yes
```

で新しいホスト鍵を登録。

解決した。

---

## 9. 最終確認

Windows 側で

```powershell
ssh suse@10.110.0.202
```

を実行。

結果：

* パスワード不要
* 鍵認証成功
* known_hosts 正常
* Cloud-Init 正常

を確認。

---

## Lessons Learned

今回の問題の本質は SSH 鍵そのものではなく、

1. IP重複
2. Cloud-Init User=Default
3. known_hosts の古い記録

の3点だった。

特に

```text
Cloud-Init User = Default
```

は公開鍵認証が動作しない原因として見つけにくく、今後も注意が必要である。

また、Windows 側への秘密鍵コピーは手作業ではなく、

```bash
scp
```

を利用する方が確実である。
