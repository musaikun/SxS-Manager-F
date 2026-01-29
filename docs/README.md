# S×S Manager ドキュメント

このディレクトリには、プロジェクトの設計書・開発ガイド・セッションログが含まれています。

## 📚 ドキュメント一覧

### 設計・アーキテクチャ
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - システム全体設計
  - ディレクトリ構造
  - データモデル設計
  - Provider設計
  - 画面遷移フロー
  - 制約事項

- **[FEATURES.md](./FEATURES.md)** - 機能一覧と優先順位
  - 実装済み機能
  - 今後の実装計画（Phase 2〜5）
  - 各機能の詳細仕様

- **[SESSION_PLAN.md](./SESSION_PLAN.md)** - セッション分割実行プラン
  - プランA: 実用重視（推奨）
  - プランB: 段階的設計（上級者向け）
  - セッション実行テンプレート
  - 競合発生時の対処フロー

### セッションログ
- **[session_logs/](./session_logs/)** - 各セッションの実装記録
  - `session_001_date_selection_improvements.md` - 日付選択画面の改善
  - `TEMPLATE.md` - 新規セッション用テンプレート

## 🚀 開発開始時の推奨フロー

### 1. 新しいセッションを開始する前に
```bash
# 1. developブランチを最新化
git checkout develop
git pull origin develop

# 2. ドキュメントを確認
cat docs/ARCHITECTURE.md      # システム構造を理解
cat docs/FEATURES.md          # 実装すべき機能を確認
cat docs/SESSION_PLAN.md      # セッション分割方針を確認
```

### 2. 新しい機能を実装する
```bash
# 3. 機能ブランチを作成
git checkout -b feature/your-feature-name

# 4. Claude Codeに指示
"Please implement [機能名] according to docs/FEATURES.md"
```

### 3. セッション終了時
```bash
# 5. コミット＆プッシュ
git add .
git commit -m "feat: implement [機能名]"
git push -u origin feature/your-feature-name

# 6. セッションログを作成（テンプレートを使用）
cp docs/session_logs/TEMPLATE.md docs/session_logs/session_XXX_feature_name.md
# → 編集してセッション内容を記録

# 7. developにマージ
git checkout develop
git merge feature/your-feature-name
git push origin develop
```

## 📋 次に実装すべき機能（推奨順）

### 優先度：高
1. **一括時間設定**
   - セッション: 1回
   - ファイル: `shift_list_screen.dart` 改修
   - 詳細: [FEATURES.md#2-1](./FEATURES.md)

2. **デフォルト時間設定**
   - セッション: 1回
   - ファイル: 新規 `default_time_provider.dart`
   - 詳細: [FEATURES.md#2-1](./FEATURES.md)

### 優先度：中
3. **確認・提出画面**
   - セッション: 1回
   - ファイル: 新規 `confirmation_screen.dart`
   - 詳細: [FEATURES.md#3-1](./FEATURES.md)

### 優先度：低
4. **時給計算・集計機能**
   - セッション: 3回（段階的）
   - ファイル: 新規ディレクトリ `features/wage/`
   - 詳細: [FEATURES.md#4-1](./FEATURES.md)

## ⚠️ 注意事項

### 競合を避けるためのルール
1. **同じファイルを複数セッションで編集しない**
2. **既存ファイルの改修は慎重に（1セッション完結推奨）**
3. **新機能は新規ファイルで実装（競合リスク最小）**

### セッション開始前の必須確認
- [ ] 最新のdevelopブランチをpull
- [ ] ARCHITECTURE.md を確認
- [ ] FEATURES.md で実装内容を確認
- [ ] 前回のセッションログを確認

## 🛠️ トラブルシューティング

### マージ競合が発生した場合
```bash
git merge develop
# CONFLICT が発生

# 対処法1: Claude Codeに依頼
"I have a merge conflict in [ファイル名]. Please help resolve it."

# 対処法2: 手動で解決
# <<<<<<< HEAD と ======= の間があなたのコード
# ======= と >>>>>>> develop の間がdevelopのコード
# 両方を統合して保存

git add [ファイル名]
git commit -m "Merge develop and resolve conflicts"
```

### セッション間の仕様不一致
- → `ARCHITECTURE.md` を参照してインターフェースを確認
- → 必要に応じて `ARCHITECTURE.md` を更新

### どのファイルを変更すべきか迷った場合
- → `docs/FEATURES.md` の該当機能を確認
- → `docs/ARCHITECTURE.md` のディレクトリ構造を参照

## 📝 ドキュメント更新ガイドライン

### いつ更新すべきか
- 新しいモデルやProviderを追加した → `ARCHITECTURE.md` を更新
- 新機能を実装した → `FEATURES.md` をチェック✅に更新
- セッション完了時 → `session_logs/` に新規ログ作成

### 更新担当
- Claude Code: 自動的に提案・更新
- 開発者: 最終確認と承認

## 🔗 関連リソース

- プロジェクトルート: `/home/user/SxS-Manager-F/`
- ソースコード: `lib/features/shift/`
- 設計書: `docs/` (このディレクトリ)
- Git管理: `develop` ブランチが統合ブランチ

---

**最終更新:** 2026-01-23
**更新者:** Claude Code
