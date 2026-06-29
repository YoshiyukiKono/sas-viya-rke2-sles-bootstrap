# SAS 担当者向け NFS サーバアクセス環境の整備

Date: 2026-06-29

## 背景

SAS Viya のインストール作業は別担当者が実施する。

当初は Jump Host のみ利用できれば十分と考えていたが、SAS インストール資材やログの配置・確認は NFS サーバ上で行うことが多いため、Jump Host に加えて NFS サーバへも直接ログインできる環境を準備することにした。

構成は以下とした。

| VM | IP | 用途 |
|----|----|------|
| jump-host | 10.110.0.189 | Kubernetes 管理端末 |
| nfs | 10.110.0.190 | NFS ストレージ |

利用者は両サーバとも **sas** ユーザーでログインする。

---

## NFS サーバへログイン

```
ssh suse@10.110.0.190
```

---

## sas ユーザー作成

```bash
sudo useradd -m -s /bin/bash sas
sudo passwd sas
```

---

## sudo 権限付与

```bash
sudo usermod -aG wheel sas
```

確認

```bash
id sas
```

```bash
uid=1002(sas) gid=1002(sas) groups=1002(sas),497(wheel)
```

---

## SSH 鍵認証

SAS担当者自身に SSH 鍵を生成してもらう運用とする。

公開鍵

```
id_ed25519.pub
```

を受領後、

```bash
sudo mkdir -p /home/sas/.ssh

sudo vi /home/sas/.ssh/authorized_keys
```

公開鍵を登録する。

権限設定

```bash
sudo chown -R sas:users /home/sas/.ssh

sudo chmod 700 /home/sas/.ssh

sudo chmod 600 /home/sas/.ssh/authorized_keys
```

---

## NFS ディレクトリ確認

SAS Viya 用ディレクトリ

```bash
ls -l /srv/nfs/viya
```

共有設定確認

```bash
sudo exportfs -v
```

---

## 書き込み確認

sas ユーザーへ切り替える。

```bash
su - sas
```

テストファイル作成

```bash
touch /srv/nfs/viya/test-sas.txt
```

確認

```bash
ls -l /srv/nfs/viya
```

不要になれば削除

```bash
rm /srv/nfs/viya/test-sas.txt
```

---

## 期待する利用イメージ

SAS 担当者は以下を自身で実施できる。

- NFS 上へのインストール資材配置
- Deployment Assets の展開
- ログ確認
- インストール後成果物の確認

一方で Kubernetes 操作は Jump Host 上で実施する。

```
Jump Host (10.110.0.189)
    ↓
kubectl / helm / git

NFS (10.110.0.190)
    ↓
インストール資材
Deployment Assets
ログ
```

これにより、構築担当者の作業を待つことなく、SAS 担当者のみでインストール作業を進められる環境となった。
