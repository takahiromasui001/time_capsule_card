---
name: litestream-restore
description: Litestreamでバックアップしたデータベースのリストア手順を案内する
---

# Litestreamリストア手順ガイド

ユーザーがLitestreamのリストアを行いたい時に、以下の手順を案内する。

## 案内する手順

1. `bin/kamal shell` でコンテナに入る
2. `pkill -f puma` でPumaを停止
3. `bundle exec litestream restore -o /tmp/restored.db -config config/litestream.yml storage/production.sqlite3` でリストア
4. `sqlite3 /tmp/restored.db "PRAGMA integrity_check;"` で整合性チェック（okと出ればOK）
5. `mv storage/production.sqlite3 storage/production.sqlite3.bak` で現在のDBをバックアップ
6. `mv /tmp/restored.db storage/production.sqlite3` でリストアしたDBを配置
7. `exit` でコンテナから抜ける
8. `bin/kamal app boot` でアプリ再起動

## 補足
- 特定時点への復元: `-timestamp "2026-01-24T12:00:00Z"` オプションを追加
- 動作確認後、`bin/kamal app exec 'rm storage/production.sqlite3.bak'` でバックアップ削除
