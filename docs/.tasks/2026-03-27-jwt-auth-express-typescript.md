---
背景: Express + TypeScript 環境で JWT 認証を導入する際のベストプラクティスを把握したい。
ゴール:
  - JWT 認証の仕組み・トークン管理戦略の整理
  - Express + TypeScript での実装パターンと推奨ライブラリの特定
  - セキュリティ上の注意点と対策の明確化
制約:
  - Express + TypeScript
  - 調査のみ（実装は含まない）
---

## Phase 1: plan-research → 2026-03-27-research-jwt-auth-express-typescript.md
- ✅ a. JWT の基本構造（Header / Payload / Signature）とアルゴリズム選択（HS256 vs RS256）
- ✅ b. Access Token / Refresh Token 戦略とトークンの保存場所（Cookie vs localStorage vs メモリ）
- ✅ c. Express + TypeScript での推奨ライブラリ比較（jsonwebtoken, jose, passport-jwt 等）
- ✅ d. ミドルウェア設計パターン（認証・認可の分離、型安全なリクエスト拡張）
- ✅ e. セキュリティ対策（トークン失効、ローテーション、CSRF/XSS 防御、レート制限）
