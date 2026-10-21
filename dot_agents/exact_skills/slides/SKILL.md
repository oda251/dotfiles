---
name: slides
description: "スライド作成時に利用。「スライドを作って」のようなスライド関連の指示に対して、常に利用する"
---

## 作成場所

`~/obsidian-vault/slide/<YYYY-MM-DD>-<title>.md`。slidev プロジェクトとローカルテーマ (`theme/<name>/`) を同ディレクトリに用意してある。

## frontmatter

```yaml
---
theme: ./theme/<name>
title: タイトル
---
```

theme は以下の候補をユーザに提示し、確認を取って決める:

!`ls ~/obsidian-vault/slide/theme`

## 起動

`cd ~/obsidian-vault/slide && slidev <作成したスライドのパス>` をバックグラウンド実行し、URL をユーザーに伝える。
