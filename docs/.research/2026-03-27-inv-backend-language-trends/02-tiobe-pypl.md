---
tags:
  - investigation
  - backend
  - programming-language
  - tiobe
  - pypl
---
# バックエンド言語の採用トレンド 2024-2026: TIOBE / PYPL ランキング

## TIOBE Index（2026年3月）

TIOBE Index は検索エンジン上の各言語に関するコンテンツ量を推定し、ランキングを算出する（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。

### 対象言語のランキング

| 順位 | 言語 | レーティング | 前年比 |
|------|------|-------------|--------|
| 1 | Python | 21.25% | -2.59% |
| 4 | Java | 7.99% | -2.37% |
| 5 | C# | 6.36% | +1.49% |
| 14 | Rust | 1.31% | +0.09% |
| 16 | Go | 1.29% | -1.49% |
| 18 | PHP | 1.23% | -0.25% |
| 22 | Kotlin | 0.82% | 未確認 |
| 35 | TypeScript | 0.34% | 未確認 |

出典: [TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)

### 注目点

- **Python** は首位を維持するが、前年比 -2.59% と微減傾向にある（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **C#** は前年比 +1.49% で上昇し、2025年の「Programming Language of the Year」を受賞した（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **Go** は前年比 -1.49% と大幅に下落し、16位まで後退した（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **Java** は前年比 -2.37% で4位。長期的な下落傾向が続く（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **Rust** は前年比 +0.09% でほぼ横ばいの14位（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **PHP** は前年比 -0.25% で18位。緩やかな下落が続く（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。
- **Kotlin** は22位、**TypeScript** は35位。いずれもトップ20圏外で、前年比の数値は公式ページ上で確認できなかった（[TIOBE Index for March 2026](https://www.tiobe.com/tiobe-index/)）。

## PYPL Index（2026年3月時点取得）

PYPL（PopularitY of Programming Language）Index は Google での言語チュートリアル検索頻度を基にランキングを算出する（[PYPL Index](https://pypl.github.io/PYPL.html)）。データは月次更新。2026年3月27日にアクセスした時点の最新データを記載する。

### 対象言語のランキング

| 順位 | 言語 | シェア | トレンド（前年比） |
|------|------|--------|-------------------|
| 1 | Python | 34.87% | +4.4% |
| 3 | Java | 9.82% | -5.4% |
| 7 | Rust | 3.08% | -0.0% |
| 8 | C# | 3.03% | -3.1% |
| 9 | PHP | 2.90% | -0.8% |
| 12 | TypeScript | 1.85% | -0.8% |
| 17 | Kotlin | 0.96% | -0.8% |
| 21 | Go | 0.67% | -1.3% |

出典: [PYPL PopularitY of Programming Language Index](https://pypl.github.io/PYPL.html)

### 注目点

- **Python** はシェア 34.87% で圧倒的首位。前年比 +4.4% とさらにシェアを拡大している（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **Java** はシェア 9.82% で3位だが、前年比 -5.4% と急激に下落している（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **Rust** はシェア 3.08% で7位。前年比 -0.0% で安定している（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **C#** はシェア 3.03% で8位。前年比 -3.1% と下落傾向にある（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **Go** はシェア 0.67% で21位。前年比 -1.3% で、PYPL ではチュートリアル検索需要が低い（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **TypeScript** はシェア 1.85% で12位。前年比 -0.8%（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **Kotlin** はシェア 0.96% で17位。前年比 -0.8%（[PYPL Index](https://pypl.github.io/PYPL.html)）。
- **PHP** はシェア 2.90% で9位。前年比 -0.8%（[PYPL Index](https://pypl.github.io/PYPL.html)）。

## 両指標の比較

| 言語 | TIOBE 順位 | TIOBE レーティング | PYPL 順位 | PYPL シェア |
|------|-----------|-------------------|----------|------------|
| Python | 1 | 21.25% | 1 | 34.87% |
| Java | 4 | 7.99% | 3 | 9.82% |
| C# | 5 | 6.36% | 8 | 3.03% |
| Rust | 14 | 1.31% | 7 | 3.08% |
| Go | 16 | 1.29% | 21 | 0.67% |
| PHP | 18 | 1.23% | 9 | 2.90% |
| Kotlin | 22 | 0.82% | 17 | 0.96% |
| TypeScript | 35 | 0.34% | 12 | 1.85% |

### 指標間の乖離が大きい言語

- **Rust**: TIOBE 14位 / PYPL 7位。チュートリアル検索需要（学習者の関心）が検索エンジン上のコンテンツ量に比べて高い。
- **TypeScript**: TIOBE 35位 / PYPL 12位。同様に学習需要が高いが、TIOBE の検索エンジンベースの評価では低い。TIOBE は TypeScript を JavaScript と区別しにくいという指標上の特性がある（**未検証**）。
- **C#**: TIOBE 5位 / PYPL 8位。TIOBE では前年比 +1.49% と上昇中だが、PYPL では -3.1% と下落中で、トレンドの方向が逆転している。

## 制約事項

- PYPL のデータ取得日は 2026年3月27日だが、ページ上で表示月を静的テキストとして確認できなかった（JavaScript による動的表示のため）。表示されたデータが 2026年3月分である保証はない。
- TIOBE の Kotlin・TypeScript については、21位以下のカテゴリに属し、前年比の数値が公式ページ上で提供されていなかった。
- 両指標とも計測手法が異なるため、順位・シェアの直接比較には注意が必要。TIOBE は検索エンジン上のコンテンツ量、PYPL は Google チュートリアル検索頻度を基にしている。
