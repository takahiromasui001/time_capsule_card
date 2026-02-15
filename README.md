# Time Capsule Desk

「未来の自分からの手紙」をコンセプトにした個人タスク管理アプリ。
カードに日付を指定して投函すると、その日まで非表示になり、届いたら今日の机に並べて処理する。

## コンセプト

カードは 4 つの状態を遷移する:

```
scheduled → arrived → on_desk → done
```

- **scheduled** — 未来に投函済み。指定日まで見えない
- **arrived** — ポスト（受信箱）に届いた状態
- **on_desk** — 今日の机に置いた（今日の ToDo）
- **done** — 完了・アーカイブ

机に残したまま翌朝を迎えると、自動でポストに戻る。毎日リストが新鮮になる仕組み。

## 技術スタック

- Ruby on Rails 8.1（Hotwire / Turbo + Stimulus）
- SQLite
- Tailwind CSS 4
- Google OAuth（omniauth）
- RSpec + Capybara

## セットアップ

```sh
bin/setup
```

`.env` を作成:

```
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
```

開発サーバー起動:

```sh
bin/dev
```

## デプロイ

**Kamal** + **Litestream**（SQLite を S3 にバックアップ）で運用。
詳細は [KAMAL.md](KAMAL.md) を参照。

## テスト

```sh
bundle exec rspec
```
