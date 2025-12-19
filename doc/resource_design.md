# リソース設計方針

## カードの状態遷移

```
scheduled (未来に投函) → arrived (ポスト) → on_desk (机) → done (完了)
```

## 設計原則

「移動先#create = その場所に移す」で統一。destroy は状態遷移に使わない。

## コントローラー構成

| コントローラー | アクション | 役割 |
|----------------|------------|------|
| CardsController | create | カード作成 |
| CardsController | update | Snooze（scheduled_at 更新 → scheduled に戻る） |
| CardsController | destroy | カード削除 |
| Card::PostsController | index | ポスト（arrived）の一覧 |
| Card::DesksController | index | 机（on_desk）の一覧 |
| Card::DesksController | create | 机に置く（arrived → on_desk） |
| Card::ArchivesController | index | 完了（done）の一覧 |
| Card::ArchivesController | create | 完了にする（arrived/on_desk → done） |

## 操作と状態遷移

| 操作 | 状態遷移 | エンドポイント |
|------|----------|----------------|
| 机に置く | arrived → on_desk | POST /cards/:id/desk |
| 完了（ポストから） | arrived → done | POST /cards/:id/archive |
| 完了（机から） | on_desk → done | POST /cards/:id/archive |
| 後で（Snooze） | → scheduled | PATCH /cards/:id |

## 補足

- Snooze は `scheduled_at` を未来に更新することで `scheduled` 状態に戻る
- 各場所コントローラーは index で該当状態のカード一覧を取得可能
