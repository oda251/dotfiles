# TypeScript + React ポリシー

React プロジェクト固有のルール。ts.md と併せて適用する。

## useEffect を使わない

useEffect はほぼ全てのケースで別の手段に置き換えられる。

| やりたいこと | useEffect の代わりに |
|-------------|-------------------|
| データ取得 | TanStack Query / SWR |
| URL 同期 | ルーターの searchParams |
| 派生値の計算 | useMemo またはレンダー中に直接計算 |
| イベント購読 | useSyncExternalStore |

## コンポーネント設計

- **Compound Pattern**: 関連するコンポーネントを親に紐付けてまとめる

## 状態管理の優先順位

上から順に検討し、上で解決できないときだけ下に進む。

1. **サーバー状態** → TanStack Query / SWR
2. **URL 状態** → クエリパラメータ / パスパラメータ
3. **永続化が必要な状態** → Cookie / IndexedDB
4. **クライアント共有状態** → zustand
5. **コンポーネントローカル状態** → useState（やむを得ない場合のみ）
