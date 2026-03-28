# 技術スタック: Python

Python プロジェクトの技術選定。

## パッケージマネージャ: uv

- pip/poetry/pipenv ではなく uv を使う
- `uv init`, `uv add`, `uv run` で統一
- lockfile (`uv.lock`) をコミットする

## Lint / Format: Ruff

- `ruff check` + `ruff format` で lint と format を統一
- Lefthook の pre-commit で実行する
- `UP006`（use-pep585-annotation）、`UP007`（use-pep604-annotation）を有効にする

## 型チェック: Pyright

- mypy ではなく Pyright を使う
- `reportAny`、`reportMissingParameterType`、`reportUnknownParameterType` を有効にする

## バリデーション: Pydantic

- 外部入力のバリデーションには Pydantic を使う

## テスト: pytest

- unittest ではなく pytest を使う
