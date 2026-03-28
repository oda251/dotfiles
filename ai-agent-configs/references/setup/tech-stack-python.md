# 技術スタック: Python

Python プロジェクトの技術選定。

## パッケージマネージャ: uv

- pip/poetry/pipenv ではなく uv を使う
- `uv init`, `uv add`, `uv run` で統一
- lockfile (`uv.lock`) をコミットする

## バリデーション: Pydantic

- 外部入力のバリデーションには Pydantic を使う
- `model_validate()` でパース、`ValidationError` でエラーハンドリング
