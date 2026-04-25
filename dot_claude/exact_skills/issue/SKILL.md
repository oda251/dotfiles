---
name: issue-manage
description: GitHubリポジトリにissueやFeature Requestを起票したいとき
inputs:
  repo: 対象リポジトリ（owner/name）。省略時は現在のgit remoteから推定
  topic: 起票したい内容の概要（バグ/機能要望/改善など）
  parent: 親issue番号またはURL（sub-issueとして紐付ける場合のみ）
confirm-before-run: true
---

## フロー

1. 類似issue探索
2. template & community guidelines解析
3. 証拠収集
4. draft作成（journal skill, `{org}/note/` 配下）
5. ユーザ確認
6. 投稿 / 紐付け

内部repo / 外部repo を問わず必ず draft を vault に作成してユーザ確認を取る。

---

## 1. 類似issue探索

重複起票を防ぐ。網羅性より判断に足る情報の確保を優先。

- `gh search issues --repo {repo} "{keywords}"` を open/closed 両方、複数キーワードで実行
- `gh search prs --repo {repo} "{keywords}"` で関連PRも確認
- reaction数・最終更新日時・直近コメントでコミュニティの関心度を測る
- 最新の CHANGELOG / releases に修正済み記載が無いか確認

**近接duplicateが見つかったら中断**。ユーザーに「既存issueへのコメント/reaction」を推奨し、起票を続けるか確認する。

## 2. template & community guidelines解析

### template

- `gh api repos/{repo}/contents/.github/ISSUE_TEMPLATE` で `.yml` / `.md` 両方確認
- `config.yml` の `blank_issues_enabled` を確認
- 採用済みの近接issueを3〜5件読み、tone と粒度を合わせる
- templateが無いrepoでは、最近merge/closeされたissueの構造を踏襲する

### community guidelines

投稿前に以下を確認:

- `CONTRIBUTING.md`: issue起票の手順、必須情報、ラベル運用
- `CODE_OF_CONDUCT.md`: 表現や対応の禁止事項
- `SUPPORT.md` / `.github/SUPPORT.md`: 質問は Discussions や Stack Overflow へ誘導されていないか
- `README` の contributing 節

```bash
gh api repos/{repo}/contents/CONTRIBUTING.md --jq .content | base64 -d
```

APIで取れない場合（大きなrepo・branchデフォルト違い等）は `/tmp/{repo-slug}/` に `gh repo clone` してローカルで読む。

ガイドラインに抵触する可能性があれば draft作成前にユーザーへ相談する。

## 3. 証拠収集

- **コード参照**: `path/to/file.ts:42` 形式
- **URL**: 公式doc / 仕様書 / RFC / 既存 issue/PR / ブログ記事。WebFetch で本文を確認した上で引用
- **ログ/エラー**: ユーザー提供の一次ソース。再現コマンドも併記

自明に説明できないもの（複数ソース比較、仕様解釈、競合調査、原因深掘り）は、先に note としてドキュメント化することをユーザーに提案する。

## 4. draft作成

journal skill のパス規約に従い `{org}/note/{date}-{title}.md` として作成する。

### 本文の原則

- **1 issue = 1 concern** を厳守。複数の懸念が混ざっていれば分割
- 類似issueとの差分を冒頭に明記（「#123 とは〇〇の点で異なる」）
- template の必須フィールドはすべて埋める
- バグの場合は再現手順を最小ケースまで削る

## 5. ユーザ確認

draft を `obsidian open` で見せて承認を取る。community guidelines 抵触や類似issue等の懸念があれば伝える。

## 6. 投稿 / 紐付け

### 6-1. org所属判定

```bash
gh api user --jq .login
gh api user/orgs --jq '.[].login'
gh repo view {repo} --json owner --jq .owner.login
```

repo owner が自身のloginまたは所属orgに含まれるかで内部/外部を決める。判定不能なときは外部扱い。

### 6-2. アクション

| | 内部（所属org） | 外部 |
|---|---|---|
| ユーザ承認あり | `gh issue create` で投稿 → draft に投稿URL追記 | draft残置。ユーザーが手動で投稿 |
| sub-issue紐付け | 投稿後 GitHub sub-issue API で親に紐付け | draft本文に parent URL 記載のみ |
| 報告 | issue番号・URL + draftパス + 類似issueサマリ | draftパス + 投稿先repo + 類似issueサマリ + 手動投稿案内 |

投稿コマンド:

```bash
gh issue create --repo {repo} \
  --title "..." \
  --body-file <(obsidian read vault=obsidian-vault path="{org}/note/{date}-{title}.md" | sed '/^---$/,/^---$/d') \
  --label "..."
```

投稿後、draft 末尾に投稿URLを追記:

```bash
obsidian append vault=obsidian-vault \
  path="{org}/note/{date}-{title}.md" \
  content="\n\n---\nPosted: {issue-url}"
```

### 6-3. sub-issue紐付け（該当時）

GitHub のsub-issue APIで紐付ける。`gh issue --help` で最新のサブコマンド対応を確認。

一般的には `POST /repos/{owner}/{repo}/issues/{parent}/sub_issues` で `sub_issue_id` を渡す。`sub_issue_id` は issue の **database id**（`gh api repos/{repo}/issues/{num} --jq .id`）で、node_id や issue number とは別物。

APIが想定どおり動かない場合は、親issue本文の Tasklist に `- [ ] #{child}` を追記する案をユーザーに提示する（自動編集はしない）。

---

## セルフチェック

```
□ 類似issue/PRを open/closed 両方検索したか？
□ 近接duplicate発見時にユーザーへ判断を仰いだか？
□ CONTRIBUTING / CODE_OF_CONDUCT / SUPPORT を確認したか？
□ template必須フィールドを埋めたか？
□ 主張・修正内容にインライン出典を付けたか？
□ 出典なしの情報に（未検証）を付けたか？
□ 1 issue = 1 concern か？
□ draft を journal skill の規約で vault に保存したか？
□ ユーザ確認を取ってから投稿したか？
□ 投稿後、draft末尾にissue URLを追記したか？
□ sub-issue紐付けの要否を判断したか？
```
