# Jump Host に SAS 担当者用ユーザーを作成

Date: 2026-06-21

## 背景

これまでは Jump Host を構築担当者（suseユーザー）のみが利用する前提だった。

SAS Viya のインストールは別担当者が実施するため、構築用ユーザーとは分離した利用者アカウントを作成することにした。

構成は以下とした。

| User | 用途 |
|------|------|
| suse | Kubernetes / RKE2 構築・管理 |
| sas | SAS Viya 導入担当者 |

## sas ユーザー作成

```bash
sudo useradd -m -s /bin/bash sas
sudo passwd sas
```

パスワード設定時に

```
BAD PASSWORD: it is too short
BAD PASSWORD: is too simple
```

と表示されたが、これは SLES のパスワード品質チェックによる警告であり、

```
password updated successfully
```

となれば設定自体は成功している。

---

## sudo 権限付与

SAS インストール時に追加パッケージ導入等が発生する可能性があるため、wheel グループへ追加した。

```bash
sudo usermod -aG wheel sas
```

確認

```bash
id sas
```

---

## kubeconfig 配布

構築済み RKE2 クラスタを利用できるよう、suse ユーザーの kubeconfig をコピーした。

```bash
sudo mkdir -p /home/sas/.kube

sudo cp /home/suse/.kube/config \
    /home/sas/.kube/config

sudo chown -R sas:users /home/sas/.kube

sudo chmod 600 /home/sas/.kube/config
```

---

## KUBECONFIG 永続化

```bash
sudo -u sas bash -c \
'echo "export KUBECONFIG=\$HOME/.kube/config" >> ~/.bashrc'
```

---

## 動作確認

sas ユーザーでログインし、

```bash
kubectl get nodes
```

が正常に実行できることを確認する。

---

## SSH 認証方針

当初は構築担当者が秘密鍵を配布することも考えたが、その場合、

- 同じ秘密鍵を複数人が共有する
- ログイン者の識別ができない

という問題がある。

最終的に以下の運用とした。

1. SAS担当者自身が SSH 鍵を生成する

```
ssh-keygen -t ed25519
```

2. 公開鍵（id_ed25519.pub）のみ管理者へ送付する

3. 管理者が

```
/home/sas/.ssh/authorized_keys
```

へ追加する

これにより秘密鍵を共有することなく、安全に認証できる。

---

## 今後

Jump Host は SAS 担当者が Kubernetes 管理端末として利用する。

最低限利用できることを確認する。

```
kubectl
helm
git
wget
jq
docker
kustomize
```

その後、SAS Viya のインストール作業へ引き継ぐ。
