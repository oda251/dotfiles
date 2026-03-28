# Python ガイドライン

プロジェクト横断で適用する Python 共通ルール。

## 型

### TypedDict / dataclass / Pydantic の使い分け

| 用途 | 使うもの |
|---|---|
| 外部入力のバリデーション | Pydantic `BaseModel` |
| 内部のデータ構造 | `dataclass` (mutable) / `@dataclass(frozen=True)` (immutable) |
| dict のスキーマ定義 | `TypedDict` |

### NewType でプリミティブ型を区別する

```python
from typing import NewType

UserId = NewType("UserId", str)
OrderId = NewType("OrderId", str)

def get_user(user_id: UserId) -> User: ...
```

## エラーハンドリング

### 例外は境界で catch する

内部ロジックでは例外を投げてよい。catch するのは API ハンドラ・CLI エントリポイント等の境界。

```python
# 内部: 素直に raise
def withdraw(account: Account, amount: int) -> None:
    if account.balance < amount:
        raise InsufficientFundsError(account.id, amount)

# 境界: ここで catch
try:
    withdraw(account, amount)
except InsufficientFundsError as e:
    return ErrorResponse(str(e))
```

### カスタム例外は具体的に

`Exception` や `ValueError` を直接 raise しない。ドメイン固有の例外クラスを定義する。

```python
class InsufficientFundsError(Exception):
    def __init__(self, account_id: str, amount: int) -> None:
        super().__init__(f"Account {account_id}: insufficient funds for {amount}")
```
