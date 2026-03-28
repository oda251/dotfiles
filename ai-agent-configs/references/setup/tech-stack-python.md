# 技術スタック: Python

Python プロジェクトの技術選定。

## パッケージマネージャ: uv

- pip/poetry/pipenv ではなく uv を使う
- `uv init`, `uv add`, `uv run` で統一
- lockfile (`uv.lock`) をコミットする

## Lint / Format: Ruff

- `ruff check` + `ruff format` で lint と format を統一
- Lefthook の pre-commit で実行する
- ルール: `UP006`, `UP007`, `B` (bugbear), `SIM` (simplify), `I` (isort), `TRY003`, `BLE001`, `RUF`, `PT`, `T20`, `ERA`

## 型チェック: Pyright

- mypy ではなく Pyright を使う
- `typeCheckingMode: "strict"` を使う

## バリデーション: Pydantic

- 外部入力のバリデーションには Pydantic を使う

## テスト: pytest

- unittest ではなく pytest を使う
