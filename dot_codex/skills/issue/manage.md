---
description: GitHubリポジトリにissueやFeature Requestを起票したいとき
inputs:
  repo: 対象リポジトリ（owner/name）。省略時は現在のgit remoteから推定
  topic: 起票したい内容の概要（バグ/機能要望/改善など）
  parent: 親issue番号またはURL（sub-issueとして紐付ける場合のみ）
confirm-before-run: true
---

## フロー

1. 類似issue探索
2. template解析
3. 証拠収集
4. draft作成
5. org所属判定 → 内部/外部に分岐
6. 投稿 / 紐付け（sub-issueは該当時のみ）

---

## 1. 類似issue探索

網羅性より判断に足る情報の確保を優先する。同じ課題を重複起票させないのが目的。

- `gh search issues --repo {repo} "{keywords}"` を open/closed 両方、複数キーワードで実行
- `gh search prs --repo {repo} "{keywords}"` で関連PRも確認
- reaction数、最終更新日時、直近コメントを確認してコミュニティの関心度を測る
- 最新の CHANGELOG / releases に修正済み記載が無いか確認

**近接duplicateが見つかった場合は中断**。ユーザーに「既存issueへのコメント/reaction」を推奨し、起票を続けるか確認する。

## 2. template解析

- `.github/ISSUE_TEMPLATE/` の中身を `gh api repos/{repo}/contents/.github/ISSUE_TEMPLATE` で確認（`.yml` / `.md` 両方）
- `config.yml` の `blank_issues_enabled` を確認
- 採用済みの近接issueを3〜5件読み、tone と粒度を合わせる

templateが無いrepoでは、最近merge/closeされたissueの構造を踏襲する。

## 3. 証拠収集

本文に書く**主張・修正内容・背景の根拠**には、必ず出典を付ける。根拠なしの主張は書かない（書くなら `（未検証）` と明記）。出典ルールは documentation skill に準拠し、情報単位ごとにインラインで引く。

### 証拠の種類

- **コード参照**: `path/to/file.ts:42` 形式。内部repoは Grep/Read、外部repoは必要に応じて `/tmp` に clone して確認
- **URL**: 公式doc / 仕様書 / RFC / 既存 issue/PR / ブログ記事。**WebSearch のスニペットは出典にしない**。必ず WebFetch で本文を読んだ上で引用
- **ログ/エラー**: ユーザーから提供された一次ソースを引く。再現時のコマンドも併記

### research skill との連携

**修正内容・主張が自明に説明できる場合でなければ、research skill (gather.md) の起動をユーザーに提案する**。

- **自明に説明可能（gather提案不要）**: typo修正、明確に局所化されたバグ（stack trace + 該当コードで説明完結）、自明な文言変更、templateが促す定型項目のみで充足するケース
- **それ以外（gather提案）**: 複数ソースの比較が必要、仕様解釈が絡む、競合調査が要る、原因特定に深掘りが必要 — これらは `research/gather.md` を実行して vault の `{org}/.research/{date}-{topic}/` に証拠を蓄積し、draft はそこから引く

ユーザーが gather 起動を断った場合は、現在手元にある証拠のみで書き、不足分は `（未検証）` と明記する。捏造しない。

## 4. draft作成

- **1 issue = 1 concern** を厳守。複数の懸念が混ざっている場合は分割する
- 類似issueとの差分を本文冒頭に明記（「#123 とは〇〇の点で異なる」）
- 必須フィールドはすべて埋める。埋められない項目は「わかりません」と正直に書く
- バグの場合は再現手順を最小ケースまで削る
- 憶測や未検証の原因分析を断定形で書かない。「～の可能性がある」と留保し、必ず `（未検証）` を付す
- 収集した証拠（file:line、URL、ログ）を主張に紐付けてインラインで引用する

draft本文は一時ファイル（例: `/tmp/issue-body.md`）に保存する。

## 5. org所属判定

```bash
gh api user --jq .login
gh api user/orgs --jq '.[].login'
```

これらの結果に repo owner が含まれるか判定する（`gh repo view {repo} --json owner --jq .owner.login` でowner取得）。判定不能なときは外部ルートにフォールバックする。誤って他人のrepoへ投稿する事故を避けるため。

## 6. 投稿 / 紐付け

| | 内部（所属org） | 外部 |
|---|---|---|
| 起票 | `gh issue create --repo {repo} --title ... --body-file /tmp/issue-body.md --label ...` で投稿 | vault に `{org}/draft/{date}-{topic}.md` として `obsidian create` で保存（投稿しない） |
| sub-issue紐付け | GitHub sub-issue API で親に紐付け | draft frontmatter に `parent-issue: {url}` を記載 |
| 報告 | issue番号・URL + 類似issueサマリ | draftパス（vault内） + 投稿先repo + 類似issueサマリ |

### 補足

**draft frontmatter（外部）**: documentation skill の規則に従い、vault `obsidian-vault` に `draft` prefix で書き込む。

```yaml
---
tags:
  - draft
  - {org}/{repo}       # nested tag（例: anthropic/claude-code）
  - {topic-keyword}
status: draft           # draft / posted（投稿後に更新）
target-repo: {owner/name}
parent-issue: {url}    # sub-issueの場合のみ
similar-issues:
  - {url}: {title}（{state}, {reactions}）
sources:
  - {URL or file:line}: {何の根拠か}
research-dir: "[[{org}/.research/{date}-{topic}/]]"  # gatherを実行した場合のみ（wikilink）
---
```

書き込みコマンド例:

```bash
obsidian create vault=obsidian-vault \
  path="{org}/draft/{date}-{topic}.md" \
  content="$(cat /tmp/issue-body.md)"
```

**sub-issue API（内部）**: `gh api` 経由で叩く。gh CLI の最新コマンド対応は `gh issue --help` で確認すること。一般的には `POST /repos/{owner}/{repo}/issues/{parent}/sub_issues` で `sub_issue_id` を渡すが、これは issue の **database id**（`gh api repos/{repo}/issues/{num} --jq .id`）であり、node_id や issue number とは別物。APIが想定どおり動かない場合はフォールバックとして親issue本文の Tasklist に `- [ ] #{child}` を追記する案をユーザーに提示する（自動編集はしない）。

---

## セルフチェック

```
□ 類似issue/PRを open/closed 両方検索したか？
□ 近接duplicate発見時にユーザーへ判断を仰いだか？
□ template必須フィールドを埋めたか？埋められない項目は正直に書いたか？
□ 主張・修正内容にインライン出典を付けたか？
□ 自明でない主張について research/gather 起動を提案したか？
□ 出典なしの情報に（未検証）を付けたか？
□ 1 issue = 1 concern か？
□ org所属判定を実行し、ルート選択を明示したか？
□ sub-issue紐付けの要否を判断したか？
```
