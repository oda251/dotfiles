---
name: slides
description: "スライド作成時に利用。「スライドを作って」のようなスライド関連の指示に対して、常に利用する"
---

`~/.references/slidev-template.md` を参照し、その規約に従ってスライドを作成する。

スライドファイルの作成先は `~/obsidian-vault/slides/<name>.md`。同ディレクトリに slidev プロジェクト (`package.json` + `node_modules`) を用意してあるので、起動も同ディレクトリから行う。

作成後は `cd ~/obsidian-vault/slides && bun x slidev <作成したスライドのパス>` をバックグラウンド実行し、起動した URL をユーザーに伝える。
