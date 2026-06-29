# NFS Provisioner の archiveOnDelete による archived-* ディレクトリの確認

Date: 2026-06-29

## 背景

SAS Viya 用 RKE2 クラスタの構築後、NFS サーバ上の共有ディレクトリを確認した。

対象ディレクトリ：

```bash
ls -l /srv/nfs/viya
````

確認結果：

```text
drwxrwxrwx 2 root root 6 Jun 21 19:42 archived-default-test-rwx-pvc-pvc-b8e9518d-536a-47b8-bd1c-070127fdee0c
```

`archived-default-test-rwx-pvc-...` というディレクトリが存在していることに気づいた。

---

## 原因

このディレクトリは、NFS Subdir External Provisioner によって作成された PVC の削除後アーカイブである。

今回、NFS Provisioner 導入時に以下を指定していた。

```bash
--set storageClass.archiveOnDelete=true
```

そのため、PVC を削除した際に、NFS 上の実体ディレクトリは即時削除されず、以下の形式でリネームされる。

```text
archived-<namespace>-<pvc-name>-<pv-or-pvc-uid>
```

今回のディレクトリ名は以下を意味する。

```text
archived-default-test-rwx-pvc-pvc-b8e9518d-536a-47b8-bd1c-070127fdee0c
```

| 要素               | 意味                  |
| ---------------- | ------------------- |
| archived         | 削除済みPVC由来の退避ディレクトリ  |
| default          | PVCが存在していたNamespace |
| test-rwx-pvc     | PVC名                |
| pvc-b8e9518d-... | 対応するPV/PVC UID      |

---

## 確認

中身を確認した。

```bash
ls -la /srv/nfs/viya/archived-default-test-rwx-pvc-pvc-b8e9518d-536a-47b8-bd1c-070127fdee0c
```

結果、中身は空だった。

これは、PVC の作成確認は行ったが、実際のデータを書き込んでいなかったためと考えられる。

---

## 解釈

これは異常ではなく、`archiveOnDelete=true` による正常な挙動である。

PVC削除時の挙動は以下。

```text
PVC削除
  ↓
PV削除
  ↓
NFS上の実体ディレクトリを削除せず退避
  ↓
archived-* として残す
```

この仕組みにより、誤って PVC を削除した場合でも、NFS 上のデータを確認・退避・復旧できる可能性が残る。

---

## 運用上の考え方

SAS Viya のように Stateful なデータを扱う環境では、`archiveOnDelete=true` は安全側の設定として有用である。

一方で、PoC や検証環境では、不要な `archived-*` ディレクトリが蓄積する可能性がある。

そのため、引き渡し前や検証完了後には、不要なテスト用アーカイブを確認・削除する。

---

## 今回の対応

今回の `archived-default-test-rwx-pvc-*` は、テスト用 PVC `test-rwx-pvc` に由来するものであり、中身も空だった。

そのため削除して問題ないと判断した。

削除例：

```bash
sudo rm -rf /srv/nfs/viya/archived-default-test-rwx-pvc-*
```

---

## 関連するテストファイル

同じディレクトリには、過去の NFS 書き込み確認用ファイルも存在していた。

例：

```text
test-rke2-control-plane.txt
test-viya-control.txt
test-viya-compute.txt
test-viya-cas.txt
test-viya-stateful.txt
test-viya-stateless.txt
```

これらも構築時の疎通確認用ファイルであり、本番引き渡し前には整理対象となる。

---

## 学び

`archived-*` ディレクトリは障害やゴミではなく、NFS Provisioner のデータ保護機能による退避ディレクトリである。

今後、NFS 上に `archived-*` が存在する場合は、まず以下を確認する。

```bash
ls -la /srv/nfs/viya/archived-*
```

中身が不要であることを確認したうえで削除する。

SAS Viya 本番利用時には、誤削除時の復旧余地を残すため、`archiveOnDelete=true` のまま運用する方針が妥当と考える。

