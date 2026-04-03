# Slidev スライドテンプレート

Slidev でスライドを作成する際のテンプレート。

## frontmatter

```yaml
---
theme: default
title: タイトル
---
```

## グローバルスタイル

frontmatter 直後に配置する。ヘッダは左上固定、コンテンツは垂直中央揃え。

```html
<style>
.slidev-layout {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.slidev-layout > h1,
.slidev-layout > h2,
.slidev-layout > h3 {
  position: absolute;
  top: 3rem;
  left: 3.5rem;
}
</style>
```

## スライド区切り

`---` で区切る。

## 起動

```bash
slidev path/to/slides.md
```

alias が設定済みのため、どのディレクトリからでも相対パスで実行可能。
