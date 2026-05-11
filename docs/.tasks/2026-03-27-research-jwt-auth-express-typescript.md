---
parent: 2026-03-27-jwt-auth-express-typescript.md
parent-phase: 1
調査テーマ: Express + TypeScript 環境での JWT 認証ベストプラクティス
調査の目的: 技術選定と実装判断の基礎情報を得る
必要な粒度: 実装詳細レベル（ライブラリ選択・設計パターンまで踏み込む）
---

## Phase 1: exec-research
- ✅ a. JWT の基本構造（Header / Payload / Signature）とアルゴリズム選択（HS256 vs RS256 vs ES256）
- ✅ b. Access Token / Refresh Token 戦略とトークン保存場所の比較（httpOnly Cookie vs localStorage vs メモリ）
- ✅ c. Express + TypeScript 向けライブラリ比較（jsonwebtoken, jose, passport-jwt）
- ✅ d. ミドルウェア設計パターン（認証・認可の分離、型安全なリクエスト拡張、エラーハンドリング）
- ✅ e. セキュリティ対策（トークン失効・ブラックリスト、ローテーション、CSRF/XSS 防御、レート制限）

## Phase 2: exec-research-write
- ✅ a. 調査結果を統合ドキュメントにまとめる → docs/2026-03-27-inv-jwt-auth-express-typescript.md
