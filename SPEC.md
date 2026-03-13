# タイムボクシングアプリ 仕様書

## 1. アプリ概要

タスクにスケジュールを紐づけ、時間をブロック（タイムボックス）として管理するアプリ。  
月間カレンダーで予定を俯瞰し、日別タイムラインで1時間単位の作業・休憩を可視化する。  
ポモドーロ的な休憩ループと通知機能により、集中と休憩のリズムを維持できる。

---

## 2. 対応環境

| 項目 | 内容 |
|------|------|
| 対応デバイス | iPhone / Mac (Mac Catalyst) |
| 最低 iOS バージョン | iOS 17以上 |
| データ同期 | ローカルのみ（iCloud 同期なし） |

---

## 3. 技術スタック・アーキテクチャ

| 項目 | 内容 |
|------|------|
| UI フレームワーク | SwiftUI |
| データ永続化 | SwiftData |
| アーキテクチャ | MVVM（Feature フォルダ分割） |
| 通知 | UNUserNotificationCenter |

### フォルダ構成

```
タイムボクシング/
  Features/
    Calendar/
      Views/
        CalendarView.swift
        CalendarDayCellView.swift
      ViewModels/
        CalendarViewModel.swift
    DaySchedule/
      Views/
        DayScheduleView.swift
        TimeBoxView.swift
        ScheduleDetailView.swift
      ViewModels/
        DayScheduleViewModel.swift   ← タイムラインレイアウト・ズーム管理
        ScheduleDetailViewModel.swift
    Schedule/
      Views/
        ScheduleFormView.swift
      ViewModels/
        ScheduleFormViewModel.swift
    Task/
      Views/
        TaskFormView.swift
      ViewModels/
        TaskFormViewModel.swift
    TaskList/
      Views/
        TaskListView.swift
      ViewModels/
        TaskListViewModel.swift
    Timer/
      Views/
        TimerView.swift
      ViewModels/
        TimerViewModel.swift
  Resources/
    Sounds/
      task.m4a    ※ git管理外（後述）
      rest.m4a    ※ git管理外（後述）
  Shared/
    Models/
      TaskItem.swift
      ScheduleItem.swift
    Services/
      NotificationService.swift
      AudioService.swift
      TimerService.swift
    Components/
      FloatingAddButton.swift
      TaskTagView.swift
      FlowLayout.swift
    Extensions/
      Color+Hex.swift
  タイムボクシングApp.swift
  ContentView.swift
```

### MVVM 責務分担

| 層 | 責務 |
|----|------|
| View | 描画・ユーザー入力のみ。`@Query` による読み取り専用のデータ参照は許容する |
| ViewModel | ビジネスロジック・状態管理・SwiftData への書き込み操作 |
| Model | データ定義のみ。Foundation + SwiftData に限定し UI 依存なし |

---

## 4. データ構造

### Task（タスク）

```swift
@Model class TaskItem {
    var id: UUID
    var name: String          // タスク名（重複禁止）
    var colorHex: String      // 16進数カラーコード（例: "#FFB3B3"）
    @Relationship(deleteRule: .cascade, inverse: \ScheduleItem.task)
    var schedules: [ScheduleItem]  // タスク削除時に紐づくスケジュールも削除
}
```

### Schedule（スケジュール）

```swift
@Model class ScheduleItem {
    var id: UUID
    var task: TaskItem?       // 紐づくタスク（必須）
    var startDateTime: Date   // 開始日時
    var endDateTime: Date     // 終了日時（自動計算）
    var loopCount: Int        // 休憩ループ回数（0〜5）
    var workMinutes: Int      // タスク時間（1〜1440分）
    var breakMinutes: Int     // 休憩時間（1〜1440分）

    // 表示用ヘルパープロパティ
    var displayTaskName: String        // タスク名（タスク未設定時は "タスクなし"）
    var displayColorHex: String        // カラーコード（タスク未設定時は "#D9D9D9"）
    var timeBoxSegments: [TimeBoxSegment]  // タイムライン表示用の作業/休憩セグメント配列
}
```

### TimeBoxSegment（タイムライン表示 / タイマー共用セグメント）

```swift
struct TimeBoxSegment: Identifiable {
    let id: String            // "{scheduleId}-work-{i}" または "{scheduleId}-break-{i}"
    let index: Int            // フラットインデックス（0始まり。タイマー進捗判定に使用）
    let startTime: Date       // セグメントの開始時刻
    let endTime: Date         // セグメントの終了時刻
    let displayName: String   // 表示名（例: "読書（作業）"、"読書（休憩）"）
    let colorHex: String      // タスクカラー
    let isBreak: Bool         // true: 休憩セグメント、false: 作業セグメント
    let parentScheduleID: UUID  // 元のスケジュールID（詳細シート表示用）
    let phase: TimerPhase     // .work または .breakTime（詳細画面の表示用）
    let minutes: Int          // このセグメントの時間（分）（詳細画面の表示用）

    enum Status {
        case pending           // 実行前
        case inProgress        // 実行中
        case completed         // 実行済み
    }
}
```

`ScheduleItem.timeBoxSegments` の生成ルール:
- `loopCount == 0` の場合: 「タスク名（作業）」1件のみ（index: 0）
- `loopCount > 0` の場合: 「タスク名（作業）」→「タスク名（休憩）」を loopCount 回繰り返す配列（index は 0 から連番）

---

## 5. 画面一覧と仕様

### 5.1 月間カレンダー画面

**表示内容**
- アプリ起動時に表示する初期画面
- ヘッダーに「YYYY年MM月」を表示
- 曜日ヘッダーを左から「月火水木金土日」の順で表示
- 選択中の月の日数分（2月なら28/29日、4月なら30日など）だけ日付ボックスを表示
- 今日の日付は背景色でハイライト表示

**月の切り替え**
- 左右スワイプで前月・次月に切り替える
- ヘッダーの「‹」「›」ボタンでも切り替え可能

**スケジュールの有無表示**
- 月間カレンダー上にスケジュール有無のドット表示は行わない

**曜日カラー**
- 月〜金: `.secondary`（グレー）
- 土: `.red`（赤）
- 日: `.blue`（青）
- 今日の日付セルの日付テキスト: 白（青背景のため）

**操作**
- 日付ボックスをタップ → 日別スケジュール画面に遷移
- 右下のプラスボタン → スケジュール追加 / タイマー メニューを表示

---

### 5.2 日別スケジュール画面

**表示内容**
- 選択した日付のタイムラインを表示
- ナビゲーションタイトルに「M月D日（曜日）」を表示
- 時間軸: 0:00〜24:00 を画面左側に縦表示
- 1時間ごとに水平 divider を表示
- その日に登録されたスケジュールを、時間帯に応じてタイムボックスとして表示

**タイムボックス**
- 作業・休憩を別ボックスで表示する（`TimeBoxSegment` 単位で描画）
- 表示名: 「タスク名（作業）」「タスク名（休憩）」
- 開始時間〜終了時間の高さで表示（最低高さ 24pt）
- 背景色: 紐づくタスクの `colorHex`（休憩ボックスは opacity 0.4 で薄めに表示）
- 同一時間帯に複数のタイムボックスが重なる場合は横並びで表示（スケジュール単位でカラム分割）
  - `GeometryReader` で親の幅を取得し、カラム数で均等分割して配置
- タイムボックスをタップ → 親スケジュールのタイムボックス詳細シートを表示

**空状態**
- スケジュールが0件の場合も、0:00〜24:00のタイムラインを表示する（空状態メッセージは表示しない）

**操作**
- 右下のプラスボタン → スケジュール追加 / タイマー メニューを表示

---

### 5.2.1 タイムラインズーム

- デフォルトの1時間あたりの縦幅: **78pt**（`DayScheduleViewModel.defaultHourHeight`）
- 最小縦幅: 40pt / 最大縦幅: 200pt
- `MagnifyGesture` による2本指ピンチで縦幅を動的に変更
- ピンチイン: 縦幅を縮小（より多くの時間帯を表示）
- ピンチアウト: 縦幅を拡大（より細かく時間帯を表示）

---

### 5.3 スケジュール追加 / 編集画面

**表示形式**
- 全画面シートで表示
- 新規作成・編集で同じ UI を使い回す

**タスク選択エリア（画面上部）**
- 登録済みタスクを Tag 形式で折り返しレイアウト（FlowLayout）で一覧表示
- Tag の背景色: そのタスクの `colorHex`
- 選択中の Tag: 青枠でハイライト
- 一覧の先頭には「+ タスク追加」プレースホルダーTag を常時表示
  - 点線カプセル枠のスタイル（`StrokeStyle(lineWidth: 1.5, dash: [4])`）
  - タップ → タスク追加画面をボトムシートで表示
- セクションヘッダー右上に編集ボタン（`pencil.circle`）を表示
  - タップ → タスク一覧画面を全画面シートで表示

**入力項目**

| 項目 | 内容 |
|------|------|
| タスク選択 | Tag から1つ選択（必須） |
| 開始日時（1行目） | 月日ピッカー + 時間ピッカー |
| 終了日時（2行目） | 自動計算結果を読み取り専用で表示 |
| 休憩ループ回数 | ボタン選択: 0回 / 1回 / 2回 / 3回 / 4回 / 5回 |
| タスク時間 | 分単位入力 + ステッパー（1〜1440分）、左カラム表示 |
| 休憩時間 | 分単位入力 + ステッパー（1〜1440分）、右カラム表示 |

**休憩時間ピッカーの制御**
- 休憩ループ回数が「0回」の場合: 休憩時間入力を薄い色（disabled）で表示し、操作不可にする

**保存の挙動**
- 保存 → 日別タイムラインにタイムボックスが反映される
- 初めてスケジュールを保存するとき、通知の許可を求める
- 保存後: シートを閉じる

**日をまたぐスケジュール**
- 許可する（例: 2026/03/11 23:00 〜 2026/03/12 01:00）

---

### 5.4 タスク追加画面

**表示形式**
- ボトムシートで表示（`.presentationDetents([.medium])`）

**入力項目**

| 項目 | 内容 |
|------|------|
| タスク名 | テキスト入力、プレースホルダー「タスク名を追加」（重複禁止） |
| タスク色 | パステルカラー 10色のプリセットパレットから選択（5列グリッド） |

**バリデーションフィードバック**
- 同名タスクが既に存在する場合は「同じ名前のタスクが既にあります」をリアルタイム表示

**保存の挙動**
- 保存 → スケジュール追加画面の Tag 一覧に即時反映される

---

### 5.5 タイムボックス詳細シート

**表示内容**
- タスク名（タスクカラーの丸アイコン付き）
- 開始時間〜終了時間（例: 10:00〜11:30）
- ループ概要: （タスク時間 + 休憩時間）× 休憩ループ回数（loopCount > 0 の場合のみ表示）
- **セグメント一覧**: `timeBoxSegments` の各セグメントを縦並びで表示
  - 左端に色付き丸アイコン（作業: タスクカラー、休憩: `restColorHex`）
  - 「N分 作業 / 休憩」のラベル
  - 右端に実行状態バッジ（実行前 / 実行中 / 実行済み）
  - 実行中セグメントの行は薄い青背景でハイライト
  - 状態の判定は `TimerService.shared` の `currentScheduleId`・`currentCycleIndex`・`timerPhase` をもとに `ScheduleDetailViewModel.segmentStatus(for:)` で算出する

**ボタン**
- 「編集」ボタン: スケジュール追加と同じ UI の編集画面を表示
- 「削除」ボタン: スケジュールを削除し、関連する通知もキャンセルする

---

### 5.6 タスク一覧画面

**表示形式**
- 全画面シートで表示
- ナビゲーションタイトル: 「タスク一覧」

**表示内容**
- 登録済みの全タスクを縦並びで一覧表示
- 各タスクは `TaskTagView`（カプセル型タグ）で、タスクカラー背景付きで表示
- タスクが0件の場合は「タスクがありません」と表示（`ContentUnavailableView` を使用）

**編集モード**
- 右上に「編集」ボタンを設置
- 「編集」ボタン押下 → 各タグの左にマイナスボタン（`minus.circle.fill`、赤色）が出現
- ボタンテキストが「完了」に切り替わる
- マイナスボタン押下 → 対象タスクおよびカスケードで紐づく全スケジュール・通知を削除
- 「完了」ボタン押下 → 編集モード終了

**データ同期**
- タスク削除は SwiftData の `@Relationship(deleteRule: .cascade)` により紐づくスケジュールも自動削除される
- スケジュール追加画面のタスク選択エリアは `@Query` で TaskItem を参照しているため、削除後に即時反映される

---

### 5.8 タイマー画面

**表示形式**
- 全画面シートで表示
- 右上 ×ボタンで閉じる

**モード**

| モード | 条件 |
|--------|------|
| アイドル（idle） | タイマー未起動 |
| 手動モード（manual） | ユーザーが手動で分数を設定してスタート |
| スケジュール連動モード（scheduleSynced） | スケジュール開始時刻に自動起動、または `TimerService` によって自動検出 |

**アイドル時の表示**
- フェーズラベル: 「タイマー」
- 時間表示: 「00:00」
- 分数ピッカー（1〜120分）+ 「スタート」ボタン

**実行中の表示**
- フェーズラベル: 作業中（スケジュール連動時はタスク名）/ 「休憩中」
- カウントダウン表示（`MM:SS` 形式、サイズ 72pt）
- ループ進捗インジケーター（`loopCount > 0` かつスケジュール連動モードのみ）
  - ループ数分の丸アイコン、完了済みサイクルは青色
- 一時停止中はカウントダウン表示をセカンダリカラーで表示

**ボタン（スケジュール連動モード）**
- ストップ / 再開: タイマーの一時停止・再開（音楽も連動）
- キャンセル: タイマー終了・初期状態に戻す（ツールバーに消音ボタン）

**ボタン（手動モード・実行中）**
- ストップ / 再開: タイマーの一時停止・再開
- キャンセル: タイマー終了・初期状態に戻す

**自動起動と画面表示**
- `TimerService` が10秒ごとにスケジュールを監視し、開始時刻が現在時刻と重なるスケジュールを検出するとタイマーを自動スタートする
- 自動スタート時は `TimerService.shouldShowTimer = true` がセットされ、カレンダー画面・日別スケジュール画面の `onChange` でタイマー画面が自動表示される

---

### 5.9 TimerService（バックエンドサービス）

`TimerService` はタイマーのすべての状態を管理するシングルトンサービス。`TimerViewModel` と `ScheduleDetailViewModel` から参照される。

**主な責務**

| 責務 | 内容 |
|------|------|
| スケジュール監視 | 10秒ごとに SwiftData を参照し、開始時刻が現在時刻内のスケジュールを検出して自動スタート |
| タイマー制御 | カウントダウン（1秒 Timer）、一時停止・再開・キャンセル |
| フェーズ管理 | 作業→休憩→作業… の自動切り替え |
| バックグラウンド対応 | アプリがバックに移ったとき背景通知をスケジュール登録し、復帰時に経過時間を再計算 |
| 状態永続化 | `UserDefaults` にタイマー状態を保存し、アプリ再起動後も復元 |
| 音楽連動 | フェーズに応じて `AudioService` の再生・停止を制御 |

**状態フロー**

```
idle → (スケジュール開始 or 手動スタート) → running
running → (一時停止) → paused
paused → (再開) → running
running / paused → (キャンセル or タイマー完了) → idle
```

**UserDefaults キー一覧（プレフィックス: `ts_`）**

| キー | 内容 |
|------|------|
| `ts_timerState` | "running" / "paused" |
| `ts_timerMode` | "schedule" / "manual" |
| `ts_timerPhase` | "work" / "break" |
| `ts_remainingSeconds` | 残り秒数 |
| `ts_currentCycleIndex` | 現在のサイクルインデックス |
| `ts_scheduleWorkMinutes` / `ts_scheduleBreakMinutes` | スケジュールの作業/休憩時間 |
| `ts_scheduleStartDateTime` / `ts_scheduleEndDateTime` | スケジュール開始/終了日時 |
| その他 | scheduleName, colorHex, loopCount, isMuted, manualMinutes など |

---

## 6. 終了時間の自動計算ロジック

### 計算式

```
loopCount == 0 の場合:
  endDateTime = startDateTime + workMinutes（分）

loopCount > 0 の場合:
  endDateTime = startDateTime + (workMinutes + breakMinutes) × loopCount（分）
```

実装: `ScheduleItem.calculateEndDateTime(start:loopCount:workMinutes:breakMinutes:)` 静的メソッド

### 再計算のトリガー

以下のいずれかが変更されたとき、`endDateTime` を自動で上書き更新する。

- `startDateTime`（開始日時）
- `loopCount`（休憩ループ回数）
- `workMinutes`（タスク時間）
- `breakMinutes`（休憩時間）

> 終了時間を手動で変更していた場合も、自動計算結果で上書きする。

---

## 7. 通知仕様

### 通知のタイミングと文言

#### loopCount = 0 の場合

| タイミング | 通知文言 |
|-----------|---------|
| startDateTime | 「作業開始の時間です！」 |
| endDateTime | 「お疲れ様でした！」 |

#### loopCount = N（N > 0）の場合

| タイミング | 通知文言 |
|-----------|---------|
| 作業開始（i サイクル目の開始） | 「作業開始の時間です！」 |
| 休憩開始（i サイクル目の作業終了） | 「休憩の時間です！」 |
| スケジュール終了（endDateTime） | 「お疲れ様でした！」 |

**通知時刻の計算（N ループ時）**

```
サイクル i（0始まり）:
  作業開始: startDateTime + (workMinutes + breakMinutes) × i
  休憩開始: startDateTime + (workMinutes + breakMinutes) × i + workMinutes
```

### 通知 ID の管理

- 通知 ID: `{scheduleId}_{index}` の形式（例: `abc123_0`, `abc123_1`）
- スケジュール編集・削除時は、該当 scheduleId に紐づく全通知をキャンセルしてから再登録（または削除）する
- キャンセルはペンディング中の通知のみを対象とする（`pendingNotificationRequests()` で検索してプレフィックスマッチ）

### 通知許可のタイミング

- 初めてスケジュールを保存するときに通知許可ダイアログを表示する
- 許可されない場合は通知登録をスキップする（サイレント失敗）

---

## 8. カラーパレット

スケジュール追加画面のタスク Tag に使うパステルカラー10色。

| No. | カラーコード | イメージ |
|-----|------------|--------|
| 1 | `#FFB3B3` | ピンク |
| 2 | `#FFD9B3` | オレンジ |
| 3 | `#FFFFB3` | イエロー |
| 4 | `#B3FFB3` | グリーン |
| 5 | `#B3FFE0` | ミント |
| 6 | `#B3F0FF` | スカイブルー |
| 7 | `#B3C6FF` | ラベンダーブルー |
| 8 | `#D9B3FF` | ラベンダー |
| 9 | `#FFB3E0` | ローズ |
| 10 | `#D9D9D9` | グレー |

---

## 9. バリデーション

| 項目 | ルール |
|------|--------|
| タスク名 | 空文字禁止、同名タスクの重複禁止 |
| タスク選択 | スケジュール保存時に必須（未選択の場合は保存不可） |
| タスク時間 | 1分〜1440分（24時間）の範囲 |
| 休憩時間 | 1分〜1440分（24時間）の範囲 |
| 休憩ループ回数 | 0〜5回 |

---

## 10. 右下プラスボタンのメニュー

画面右下に常時表示する FAB（Floating Action Button）。  
タップでメニューを展開し、以下の2項目を表示する。

| メニュー項目 | 遷移先 |
|------------|--------|
| スケジュール追加 | スケジュール追加画面（全画面シート） |
| タイマー | タイマー画面（全画面シート） |

FABは月間カレンダー画面・日別スケジュール画面の両方に表示する。  
メニュー展開・閉じはスプリングアニメーション（`.spring(response: 0.3)`）で動作する。

**タスク追加・タスク一覧への動線**  
タスク追加とタスク一覧はスケジュール追加/編集画面のタスク選択セクションに集約している。  
- 「+ タスク追加」プレースホルダーTag → タスク追加画面（ボトムシート）  
- セクションヘッダー右上の編集ボタン → タスク一覧画面（全画面シート）

---

## 11. 空状態の表示

| 状況 | 表示テキスト |
|------|------------|
| タスクが0件（スケジュール追加画面） | 「タスクがありません」 |
| スケジュールが0件（日別スケジュール画面） | 0:00〜24:00のタイムラインをそのまま表示（空状態メッセージなし） |

---

## 12. 音楽再生仕様

### 対象モード
- スケジュール連動モードのみ。手動モードでは音楽を再生しない

### 音源ファイル
| フェーズ | ファイル | 用途 |
|----------|----------|------|
| 作業フェーズ | `Resources/Sounds/task.m4a` | 作業中のBGM |
| 休憩フェーズ | `Resources/Sounds/rest.m4a` | 休憩中のBGM |

### 再生タイミング
- スケジュール連動タイマー開始時に、現在のフェーズに応じた曲を再生
- フェーズ切り替え時（作業→休憩 / 休憩→作業）に曲を切り替え
- タイマー終了・キャンセル時に停止

### ループ再生
- 曲が終わったら先頭に戻りループ再生（`AVAudioPlayer.numberOfLoops = -1`）

### 一時停止・再開
- タイマー一時停止時: 音楽も一時停止
- タイマー再開時: 音楽も再開

### 消音ボタン
- タイマー画面のツールバーに表示（スケジュール連動モード時のみ）
- アイコン: `speaker.wave.2.fill`（通常）/ `speaker.slash.fill`（消音中）
- 消音状態はフェーズ切り替えや一時停止・再開後も維持

### バックグラウンド動作
- `Info.plist` の `UIBackgroundModes` に `audio` を設定
- バックグラウンドでも音楽を継続再生
- バックグラウンドでのフェーズ切り替えは通知経由で実現

---

## 13. Gitリポジトリ管理

### .gitignore ポリシー

大容量ファイルはGitHubのファイルサイズ制限（100MB）に抵触するため、`.gitignore` で管理対象外としている。

| 除外対象 | 理由 |
|---------|------|
| `*.mp3` | 音声ファイル（100MB超の場合あり） |
| `*.wav` | 音声ファイル |
| `*.aac` | 音声ファイル |
| `*.m4a` | 音声ファイル |
| `.DS_Store` | macOSシステムファイル |

### 音声ファイルの取り扱い

`Resources/Sounds/` に配置する音声ファイルはgit管理外のため、**環境構築時は手動で配置する**必要がある。

| ファイル名 | 用途 |
|-----------|------|
| `task.m4a` | タスク開始時の効果音 |
| `rest.m4a` | 休憩開始時の効果音 |

> 音声ファイルは別途共有（AirDrop等）で配布する。
