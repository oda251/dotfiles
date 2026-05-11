---
背景: SvelteKit はページごとにレンダリング戦略を選択できるフレームワーク。SSR・SSG・ISR それぞれの特性と適切なユースケースを整理したい。
ゴール:
  - SSR / SSG / ISR の仕組みと違いを明確にする
  - 各戦略の適切なユースケースと不向きなケースを整理する
  - SvelteKit での具体的な設定方法をまとめる
  - 選定フローチャート的な判断基準を提示する
制約:
  - SvelteKit 最新安定版を対象
  - adapter-node / adapter-static / adapter-vercel など主要アダプターを考慮
---

## Phase 1: plan-research
- ✅ a. [ゴールの達成](docs/.tasks/2026-03-27-research-sveltekit-rendering-strategies.md) → [調査結果](docs/2026-03-27-res-sveltekit-rendering-strategies.md)
