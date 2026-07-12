# Python ポリシー

プロジェクト横断で適用する Python 共通ルール。

## 型

- **TypedDict / dataclass / Pydantic の使い分け**: 外部入力は Pydantic、内部データは dataclass（frozen で immutable）、dict スキーマは TypedDict
- **NewType**: プリミティブ型を区別する（`UserId`, `OrderId` 等）

## エラーハンドリング

- **例外は境界で catch する**: 内部ロジックでは素直に raise。catch は API ハンドラ・CLI エントリポイント等の境界で行う
