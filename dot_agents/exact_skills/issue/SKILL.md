---
name: issue-manage
description: GitHubリポジトリにissueやFeature Requestを起票したいとき
---

## フロー

1. 類似issue探索
2. template & community guidelines解析
3. 証拠収集
4. draft作成
5. ユーザ確認
6. 投稿 / 紐付け

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

## 4. draft作成

### 本文の原則

- **1 issue = 1 concern** を厳守。複数の懸念が混ざっていれば分割
- 類似issueとの差分を冒頭に明記（「#123 とは〇〇の点で異なる」）
- template の必須フィールドはすべて埋める
- バグの場合は再現手順を最小ケースまで削る

## 5. ユーザ確認

draft でユーザに承認を取る。community guidelines 抵触や類似issue等の懸念があれば伝える。
