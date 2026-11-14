# TypeScript + React ポリシー

React プロジェクト固有のルール。ts.md と併せて適用する。

## コンポーネント設計

- Compound Pattern: 高凝集なコンポーネントを親に紐付ける

## 状態管理

安易にuseState等を使わない。下記場面を代表に、より適切な管理方法を検討する

1. サーバー状態 → TanStack Query / SWR
2. 一覧のフィルタ → クエリパラメータ
3. ユーザ設定 → Cookie / IndexedDB
4. 入力フォーム → react-hook-form
