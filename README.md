# ruby-jit-bench

Ruby の JIT コンパイラ（YJIT / ZJIT）のアーキテクチャ差を可視化するベンチマーク集。

RubyKaigi 2026 LT「RubyのJITはテスト勉強に似ている」実証実験用。

## コンセプト

- **YJIT** = 過去問ガチ勢（LBBV: 型特化した基本ブロックを逐次コンパイル）
- **ZJIT** = 教科書全理解勢（SSA HIR: メソッド全体を最適化パス付きでコンパイル）

## 実行

```sh
make all          # 全ベンチマーク + コンパイル統計
make bench        # 速度比較のみ（5回計測の中央値）
make stats        # コンパイル統計のみ
make hir          # ZJIT HIR 最適化前後の比較
make full         # bench + stats + hir すべて

# 計測回数を変更する場合
BENCH_ITER=3 make bench
```

## ベンチマーク一覧

### 基本ベンチマーク

| ファイル | 何を測るか | 有利なJIT |
|---|---|---|
| type_stable.rb | 型安定ループ（Integer演算） | YJIT |
| polymorphic.rb | 多態ディスパッチ（5クラス） | YJIT |
| recursive.rb | 再帰呼び出し（fib30） | 要実測（ZJIT有利の報告あり） |

### ZJIT アーキテクチャ検証ベンチマーク

| ファイル | 何を測るか | ZJITの最適化 | 備考 |
|---|---|---|---|
| ivar_heavy.rb | ivar冗長読み出し | load-store最適化（冗長LoadField除去） | masterで効果大 |
| setivar.rb | ivar連続代入 | Dead Store Elimination（[PR #16507](https://github.com/ruby/ruby/pull/16507)、開発中） | [Rails at Scale記事](https://railsatscale.com/2026-03-18-how-zjit-removes-redundant-object-loads-and-stores/)では ZJIT 2ms vs YJIT 5ms |
| constant_fold.rb | 定数畳み込み・DCE | fold_constants + eliminate_dead_code | SSA-IRでデータフロー解析 |
| frozen_const.rb | frozenオブジェクトのivar読み | frozen LoadField → Const 変換 | コンパイル時に値確定 |
| c_method_inline.rb | Cメソッドインライン化 | Integer#succ → FixnumAdd命令 | 後続の最適化パスと連鎖 |

## HIR 最適化比較

`make hir` で ZJIT の最適化パイプラインの before/after を確認できる。

```sh
# 個別に確認する場合（デフォルト閾値でプロファイルデータを十分に収集）
ruby --zjit --zjit-dump-hir-init -e "def add(a,b); a+b; end; 100.times{add(1,2)}"
ruby --zjit --zjit-dump-hir -e "def add(a,b); a+b; end; 100.times{add(1,2)}"
```

### ZJIT 最適化パスの実行順序

1. `type_specialize` — 型プロファイルに基づく特殊化
2. `inline` — 軽量メソッドのインライン化
3. `optimize_getivar` — ivar読み込みの最適化
4. `optimize_c_calls` — Cメソッド呼び出しの最適化
5. `convert_no_profile_sends` — プロファイルなし送信の変換
6. `optimize_load_store` — 冗長なLoadField/StoreFieldの除去
7. `fold_constants` — 定数畳み込み
8. `clean_cfg` — 制御フローグラフの整理
9. `remove_redundant_patch_points` — 冗長なパッチポイントの除去
10. `remove_duplicate_check_interrupts` — 重複割り込みチェックの除去
11. `eliminate_dead_code` — デッドコード除去

これが「教科書全理解勢」のアプローチ。YJIT（LBBV）にはこのようなパイプラインがなく、基本ブロック単位で型特化コードを直接生成する。

## Ruby HEAD の推奨

Ruby 4.0.2 時点では ZJIT の多くの最適化が未搭載。**Ruby HEAD からビルドすることを強く推奨**。

master にのみ存在する主要最適化:
- load-store最適化（冗長な LoadField/StoreField の除去）
- Lightweight Frames（JIT-to-JIT呼び出しで最大4.9%高速化）
- ポリモーフィック getivar
- no-profile send 再コンパイル
- `--zjit-dump-hir-iongraph`（Iongraph ビューア用JSON出力）

```sh
# Ruby HEAD のビルド（rbenv）
rbenv install ruby-dev
rbenv local ruby-dev
```

### Iongraph 可視化（master のみ）

```sh
ruby --zjit --zjit-dump-hir-iongraph script.rb
# /tmp/zjit-iongraph-{PID}/ に JSON 出力
# → https://mozilla-spidermonkey.github.io/iongraph/ で表示
```

## 補足

- Ruby 4.0.2 時点では多くのベンチマークで YJIT が優勢。ZJIT の load-store 最適化や DCE はまだ発展途上
- Rails at Scale の [setivar ベンチマーク](https://railsatscale.com/2026-03-18-how-zjit-removes-redundant-object-loads-and-stores/) では ZJIT 2ms vs YJIT 5ms という結果が報告されている（2026年3月時点の master。ビルドにより結果は異なる）
- 再帰 fib30 では [ZJIT が YJIT より約60%高速](https://rubykaigi.org/2025/presentations/maximecb.html) という報告あり（RubyKaigi 2025 発表時点。現ビルドでは再現しない場合がある）
- エスケープ解析+スカラー置換（[PR #16096](https://github.com/ruby/ruby/pull/16096)、クローズ済み）、Dead Store Elimination（[PR #16507](https://github.com/ruby/ruby/pull/16507)）が開発中

## 環境

- Ruby 4.0.2（rbenv）/ Ruby HEAD 推奨
- macOS ARM64
- 外部 gem 不要

## 参考

- [YJIT 公式ドキュメント](https://docs.ruby-lang.org/en/master/jit/yjit_md.html)
- [ZJIT 公式ドキュメント](https://docs.ruby-lang.org/en/4.0/jit/zjit_md.html)
- [Rails at Scale: ZJIT Load-Store 最適化](https://railsatscale.com/2026-03-18-how-zjit-removes-redundant-object-loads-and-stores/)
- [Rails at Scale: Launch ZJIT](https://railsatscale.com/2025-12-24-launch-zjit/)
- [Rails at Scale: Iongraph support](https://railsatscale.com/2025-11-19-adding-iongraph-support/)
- [ZJIT: Building a Next Generation Ruby JIT (RubyKaigi 2025)](https://rubykaigi.org/2025/presentations/maximecb.html)
