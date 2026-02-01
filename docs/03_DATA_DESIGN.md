# データ設計書

## 📊 データベース構成

### ハイブリッド構成

```
[クライアント側]
  Isar (ローカルDB)
    ↕ 同期
[サーバー側]
  Supabase (PostgreSQL)
```

**設計方針**:
- **Isar**: オフライン対応・高速読み書き
- **Supabase**: クラウド同期・複数端末対応
- **同期戦略**: Last Write Wins (最終書き込み優先)

---

## 📋 テーブル定義

### 1. Users（ユーザー）

**管理場所**: Supabase only

| カラム名 | 型 | NOT NULL | 説明 |
|---------|-----|----------|------|
| id | UUID | ✓ | ユーザーID（PK） |
| email | TEXT | ✓ | メールアドレス |
| created_at | TIMESTAMP | ✓ | 作成日時 |
| updated_at | TIMESTAMP | ✓ | 更新日時 |

**備考**:
- Supabaseの認証機能を使用（auth.users）
- カスタムフィールドは不要

---

### 2. Stores（勤務先）

**管理場所**: Isar + Supabase

#### Isar定義

```dart
@collection
class Store {
  Id id = Isar.autoIncrement; // ローカルID

  @Index(unique: true)
  late String storeId; // UUID（サーバーと同期用）

  late String name; // 店舗名
  late String color; // 色（HEX形式）

  String? phone; // 電話番号
  String? lineId; // LINE ID
  String? email; // メールアドレス

  int? hourlyWage; // 時給（円）
  int? transportationFee; // 交通費（円）

  String? memo; // メモ

  late DateTime createdAt;
  late DateTime updatedAt;
  late DateTime syncedAt; // 最終同期日時

  bool isDeleted = false; // 削除フラグ
}
```

#### Supabase定義

| カラム名 | 型 | NOT NULL | 説明 |
|---------|-----|----------|------|
| id | UUID | ✓ | 勤務先ID（PK） |
| user_id | UUID | ✓ | ユーザーID（FK） |
| name | TEXT | ✓ | 店舗名 |
| color | TEXT | ✓ | 色（HEX: #RRGGBB） |
| phone | TEXT | | 電話番号 |
| line_id | TEXT | | LINE ID |
| email | TEXT | | メールアドレス |
| hourly_wage | INTEGER | | 時給 |
| transportation_fee | INTEGER | | 交通費 |
| memo | TEXT | | メモ |
| created_at | TIMESTAMP | ✓ | 作成日時 |
| updated_at | TIMESTAMP | ✓ | 更新日時 |
| is_deleted | BOOLEAN | ✓ | 削除フラグ |

**インデックス**:
- `user_id` (パフォーマンス向上)

---

### 3. Shifts（シフト）

**管理場所**: Isar + Supabase

#### Isar定義

```dart
@collection
class Shift {
  Id id = Isar.autoIncrement; // ローカルID

  @Index(unique: true)
  late String shiftId; // UUID（サーバーと同期用）

  late String storeId; // 勤務先ID（Store.storeId）

  late DateTime date; // 勤務日
  late DateTime startTime; // 開始時刻
  late DateTime endTime; // 終了時刻

  int breakMinutes = 0; // 休憩時間（分）

  String? memo; // メモ

  late DateTime createdAt;
  late DateTime updatedAt;
  late DateTime syncedAt; // 最終同期日時

  bool isDeleted = false; // 削除フラグ

  // 計算フィールド（保存しない）
  @ignore
  int get workMinutes {
    final duration = endTime.difference(startTime);
    return duration.inMinutes - breakMinutes;
  }
}
```

#### Supabase定義

| カラム名 | 型 | NOT NULL | 説明 |
|---------|-----|----------|------|
| id | UUID | ✓ | シフトID（PK） |
| user_id | UUID | ✓ | ユーザーID（FK） |
| store_id | UUID | ✓ | 勤務先ID（FK） |
| date | DATE | ✓ | 勤務日 |
| start_time | TIMESTAMP | ✓ | 開始時刻 |
| end_time | TIMESTAMP | ✓ | 終了時刻 |
| break_minutes | INTEGER | ✓ | 休憩時間（分） |
| memo | TEXT | | メモ |
| created_at | TIMESTAMP | ✓ | 作成日時 |
| updated_at | TIMESTAMP | ✓ | 更新日時 |
| is_deleted | BOOLEAN | ✓ | 削除フラグ |

**インデックス**:
- `user_id` (パフォーマンス向上)
- `date` (日付検索の高速化)
- `store_id` (勤務先フィルタリング)

**制約**:
- CHECK: `end_time > start_time`
- CHECK: `break_minutes >= 0`

---

## 🔄 ER図

```
[Users] 1 ───────< * [Stores]
                      ↑
                      │
                      │ store_id
                      │
[Users] 1 ───────< * [Shifts] * >─── belongs to
```

**リレーション**:
1. Users - Stores: 1対多
2. Users - Shifts: 1対多
3. Stores - Shifts: 1対多

---

## 🔐 RLS（Row Level Security）

Supabaseのセキュリティポリシー:

### Stores テーブル

```sql
-- 自分のレコードのみ参照可能
CREATE POLICY "Users can view own stores"
  ON stores FOR SELECT
  USING (auth.uid() = user_id);

-- 自分のレコードのみ作成可能
CREATE POLICY "Users can insert own stores"
  ON stores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のレコードのみ更新可能
CREATE POLICY "Users can update own stores"
  ON stores FOR UPDATE
  USING (auth.uid() = user_id);
```

### Shifts テーブル

```sql
-- 自分のレコードのみ参照可能
CREATE POLICY "Users can view own shifts"
  ON shifts FOR SELECT
  USING (auth.uid() = user_id);

-- 自分のレコードのみ作成可能
CREATE POLICY "Users can insert own shifts"
  ON shifts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のレコードのみ更新可能
CREATE POLICY "Users can update own shifts"
  ON shifts FOR UPDATE
  USING (auth.uid() = user_id);
```

---

## 🔄 同期仕様

### 同期タイミング

1. **自動同期**
   - アプリ起動時
   - データ更新時（保存後5秒以内）
   - バックグラウンド復帰時

2. **手動同期**
   - 設定画面の「同期」ボタン

### 同期ロジック（Last Write Wins）

```
1. ローカルの変更をSupabaseにプッシュ
   - WHERE synced_at < updated_at

2. Supabaseの変更をローカルにプル
   - WHERE updated_at > local.synced_at

3. 競合解決
   - updated_at の新しい方を採用
   - 削除フラグ優先（is_deleted = true なら削除）

4. synced_at を更新
```

### 削除の扱い

- 物理削除ではなく論理削除（is_deleted = true）
- 同期後、一定期間経過したら物理削除（Phase 2以降）

---

## 📦 データ容量見積もり

### 1ユーザーあたり

**Stores（勤務先）**:
- 平均: 5件
- サイズ: 約500 bytes/件
- 合計: 2.5 KB

**Shifts（シフト）**:
- 月間: 60件（週15件 × 4週）
- 保存期間: 6ヶ月
- 合計: 360件
- サイズ: 約300 bytes/件
- 合計: 108 KB

**総容量**: 約110 KB/ユーザー

### Supabase無料枠

- DB容量: 500 MB
- 保存可能ユーザー数: 約4,500人

→ 個人利用なら十分

---

## 🔧 マイグレーション戦略

### Phase 1（初期リリース）

- テーブル作成
- RLS設定
- インデックス作成

### Phase 2以降

- カラム追加: `submitted_at`（シフト提出日時）
- カラム追加: `is_confirmed`（シフト確定フラグ）
- テーブル追加: `Statistics`（統計情報キャッシュ）

### バージョン管理

- Supabase: マイグレーションファイルで管理
- Isar: Flutterアプリ内でスキーマバージョン管理

---

## 📝 備考

### パフォーマンス最適化

1. **Isar**
   - インデックス: `storeId`, `date`
   - クエリキャッシュ活用

2. **Supabase**
   - 必要なカラムのみSELECT
   - ページネーション実装（Phase 2以降）

### セキュリティ

- APIキー: 環境変数で管理（.env）
- RLS: 必ず有効化
- 認証トークン: SecureStorageで保存
