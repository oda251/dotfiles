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
4. draft作成（docs skill, `{org}/note/` 配下）
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

確認項目と取得コマンド: `references/guidelines-check.md`

ガイドラインに抵触する可能性があれば draft作成前にユーザーへ相談する。

## 3. 証拠収集

- **コード参照**: `path/to/file.ts:42` 形式
- **URL**: 公式doc / 仕様書 / RFC / 既存 issue/PR / ブログ記事。WebFetch で本文を確認した上で引用
- **ログ/エラー**: ユーザー提供の一次ソース。再現コマンドも併記

自明に説明できないもの（複数ソース比較、仕様解釈、競合調査、原因深掘り）は、先に note としてドキュメント化することをユーザーに提案する。

## 4. draft作成

docs skill を経由して `{org}/note/{date}-{title}.md` として作成する。

### 本文の原則

- **1 issue = 1 concern** を厳守。複数の懸念が混ざっていれば分割
- 類似issueとの差分を冒頭に明記（「#123 とは〇〇の点で異なる」）
- template の必須フィールドはすべて埋める
- バグの場合は再現手順を最小ケースまで削る

## 5. ユーザ確認

開かれた draft でユーザに承認を取る。community guidelines 抵触や類似issue等の懸念があれば伝える。

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

投稿・URL追記コマンドと sub-issue API の詳細（database id の注意含む）: `references/posting.md`

---

## セルフチェック

手順に従えば満たされる項目は挙げない。判断を伴い漏れやすいもののみ:

```
□ 近接duplicate発見時にユーザーへ判断を仰いだか？
□ community guidelines（CONTRIBUTING / CODE_OF_CONDUCT / SUPPORT）に抵触していないか？
□ 1 issue = 1 concern か？
□ ユーザ確認を取ってから投稿したか？
```
