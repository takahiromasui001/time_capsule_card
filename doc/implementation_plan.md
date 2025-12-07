# Time Capsule Desk - 実装計画

## プロジェクト概要

**Time Capsule Desk** - 未来への手紙とタスク管理を組み合わせた Web アプリ

### コア機能

1. **投函（Write）**: カードを作成し未来の日付を指定。その場で画面から消える
2. **受信（Inbox）**: 指定日になるとポスト（画面上半分）に届く
3. **仕分け（Triage）**: Done（完了）/ Snooze（先送り）/ Keep（机へ保留）
4. **机（Desk）**: 保留にしたカードが今日の ToDo リスト（画面下半分）
5. **自動リセット**: 翌朝、机に残ったカードは自動的にポストに戻る

### 技術スタック

- Rails 8.1.1 + Hotwire (Turbo + Stimulus)
- Google OAuth 認証（複数ユーザー対応）
- Tailwind CSS
- SQLite（開発）

**注意**: バックグラウンドジョブは使用せず、ユーザーアクセス時に処理を実行

---

## Phase 1: MVP（最小限の機能）

### 1. 環境セットアップ

#### Gem 追加

```bash
bundle add omniauth omniauth-google-oauth2 omniauth-rails_csrf_protection
bundle add tailwindcss-rails
bundle add dotenv-rails --group=development,test
bundle add rspec-rails factory_bot_rails faker shoulda-matchers --group=test
```

**shoulda-matchers**: RSpec でバリデーションやアソシエーションのテストを簡潔に書くための gem

#### RSpec セットアップ

```bash
rails generate rspec:install
```

#### Tailwind CSS 導入

```bash
rails tailwindcss:install
```

#### 環境変数設定

- `.env` ファイル作成
- Google OAuth 認証情報設定（CLIENT_ID, CLIENT_SECRET）
- `.gitignore` に `.env` 追加

### 2. データモデル実装

#### User モデル

**ファイル**: `app/models/user.rb`

```ruby
class User < ApplicationRecord
  has_many :cards, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.find_or_create_from_auth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.avatar_url = auth.info.image
    end
  end
end
```

**マイグレーション**: `db/migrate/YYYYMMDDHHMMSS_create_users.rb`

- email (string, null: false, unique)
- name (string)
- avatar_url (string)
- provider (string, null: false) # "google_oauth2" - OmniAuth で必要
- uid (string, null: false) # プロバイダー提供のユーザー ID - OmniAuth で必要
- last_reset_date (date) # 最後に机をリセットした日付
- timestamps

**インデックス**:

- `email` (unique)
- `[provider, uid]` (unique)

**補足**: `provider` と `uid` は OmniAuth で必須。複数プロバイダー対応や、同じメールアドレスでも異なるプロバイダーを識別するために使用

#### Card モデル

**ファイル**: `app/models/card.rb`

```ruby
class Card < ApplicationRecord
  belongs_to :user

  enum :status, {
    scheduled: 0,   # 未来に投函済み（非表示）
    arrived: 10,    # ポストに到着
    on_desk: 20,    # 机の上
    done: 30,       # 完了
  }

  validates :title, presence: true, length: { maximum: 200 }
  validates :scheduled_at, presence: true

  # スコープ
  scope :should_arrive, -> {
    where(status: :scheduled).where('scheduled_at <= ?', Time.current)
  }
  scope :in_inbox, -> { where(status: :arrived) }
  scope :on_desk, -> { where(status: :on_desk) }

  # アクション
  def arrive!
    update!(status: :arrived)
  end

  def move_to_desk!
    update!(status: :on_desk)
  end

  def complete!
    update!(status: :done, completed_at: Time.current)
  end

  def snooze!(new_scheduled_at)
    update!(
      status: :scheduled,
      scheduled_at: new_scheduled_at,
      snoozed_count: (snoozed_count || 0) + 1
    )
  end

  def reset_to_inbox!
    update!(status: :arrived)
  end
end
```

**マイグレーション**: `db/migrate/YYYYMMDDHHMMSS_create_cards.rb`

- user_id (references, null: false, foreign_key, index)
- title (string, null: false)
- content (text)
- status (integer, null: false, default: 0)
- scheduled_at (datetime, null: false) # 配達予定日時
- completed_at (datetime) # 完了日時（統計用）
- snoozed_count (integer, default: 0)
- position (integer) # 机上の表示順
- timestamps

**インデックス**:

- `[user_id, status]`
- `[user_id, scheduled_at]`
- `[status, scheduled_at]`

**削除したカラム**: `arrived_at`, `moved_to_desk_at` - ステータスで判別できるため不要

### 3. 認証実装

#### OmniAuth 設定

**ファイル**: `config/initializers/omniauth.rb`

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'],
    ENV['GOOGLE_CLIENT_SECRET'],
    {
      scope: 'email,profile',
      prompt: 'select_account',
    }
end
```

#### SessionsController

**ファイル**: `app/controllers/sessions_controller.rb`

- `new`: ログイン画面
- `create`: OAuth callback 処理
- `destroy`: ログアウト
- `failure`: 認証失敗時

#### ApplicationController

**ファイル**: `app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    redirect_to login_path, alert: "Please sign in" unless current_user
  end
end
```

#### Google Cloud Console 設定

1. プロジェクト作成: "Time Capsule Desk"
2. OAuth クライアント ID 作成
3. リダイレクト URI: `http://localhost:3000/auth/google_oauth2/callback`
4. CLIENT_ID と SECRET を`.env`に保存

### 4. コントローラー・ルート実装

#### ルート設定

**ファイル**: `config/routes.rb`

```ruby
Rails.application.routes.draw do
  # 認証
  get 'login', to: 'sessions#new', as: :login
  post 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: 'sessions#failure'
  delete 'logout', to: 'sessions#destroy', as: :logout

  # メインアプリ
  root 'dashboard#index'

  # Cards
  resources :cards, only: [:create, :destroy] do
    member do
      patch :keep
      patch :done
      patch :snooze
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

#### DashboardController

**ファイル**: `app/controllers/dashboard_controller.rb`

```ruby
class DashboardController < ApplicationController
  before_action :deliver_scheduled_cards
  before_action :reset_desk_if_new_day

  def index
    @inbox_cards = current_user.cards.in_inbox.order(created_at: :desc)
    @desk_cards = current_user.cards.on_desk.order(position: :asc, created_at: :desc)
    @new_card = Card.new
  end

  private

  # scheduled_at が過ぎたカードを自動配達
  def deliver_scheduled_cards
    current_user.cards.should_arrive.find_each(&:arrive!)
  end

  # 日付が変わっていたら机のカードをポストに戻す
  def reset_desk_if_new_day
    today = Date.current
    if current_user.last_reset_date != today
      current_user.cards.on_desk.find_each(&:reset_to_inbox!)
      current_user.update(last_reset_date: today)
    end
  end
end
```

#### CardsController

**ファイル**: `app/controllers/cards_controller.rb`

- `create`: カード作成（scheduled 状態）
- `keep`: ポスト → 机へ移動
- `done`: 完了（アーカイブ）
- `snooze`: 再スケジュール
- `destroy`: カード削除

すべて Turbo Stream 対応で、ページ遷移なしで動作

### 5. ビュー実装

#### ログイン画面

**ファイル**: `app/views/sessions/new.html.erb`

- "Sign in with Google" ボタン
- Tailwind で中央配置、美しいデザイン

#### ダッシュボード

**ファイル**: `app/views/dashboard/index.html.erb`

```erb
<div class="h-screen flex flex-col">
  <!-- Inbox (上半分) -->
  <div class="h-1/2 bg-blue-50 p-4">
    <%= turbo_frame_tag "inbox" do %>
      <h2 class="text-2xl font-bold mb-4">Post</h2>
      <div data-controller="inbox">
        <%= render partial: "cards/inbox_card", collection: @inbox_cards %>
      </div>
    <% end %>
  </div>

  <!-- Desk (下半分) -->
  <div class="h-1/2 bg-amber-50 p-4">
    <%= turbo_frame_tag "desk" do %>
      <h2 class="text-2xl font-bold mb-4">Today's Desk</h2>
      <div id="desk_cards">
        <%= render partial: "cards/desk_card", collection: @desk_cards %>
      </div>
    <% end %>
  </div>

  <!-- Floating Action Button -->
  <button
    data-action="click->modal#open"
    class="fixed bottom-6 right-6 w-16 h-16 bg-blue-500 text-white rounded-full"
  >
    +
  </button>
</div>
```

#### カード作成フォーム

**ファイル**: `app/views/cards/_form.html.erb`

- タイトル入力
- 内容（textarea）
- 配達日時（date_field）
- 投函ボタン
- モーダル形式

#### カードパーシャル

**ファイル**: `app/views/cards/_inbox_card.html.erb`

- Keep / Done / Snooze ボタン
- data-controller="card"で Stimulus と連携

**ファイル**: `app/views/cards/_desk_card.html.erb`

- チェックボックス
- Done 時の完了処理

### 6. フロントエンド実装

#### Stimulus Controllers

**card_controller.js** (`app/javascript/controllers/card_controller.js`)

- `keep()`: 机へ移動 API コール
- `done()`: 完了 API コール
- `snooze()`: スヌーズ API コール
- CSRF トークン処理

**inbox_controller.js** (`app/javascript/controllers/inbox_controller.js`)

- カードスタック表示（重なり効果）

**form_controller.js** (`app/javascript/controllers/form_controller.js`)

- カード作成フォーム処理
- 日付バリデーション

**modal_controller.js** (`app/javascript/controllers/modal_controller.js`)

- モーダル開閉

#### Tailwind CSS

**ファイル**: `app/assets/stylesheets/application.tailwind.css`

基本スタイリング：

- カードデザイン（shadow, rounded, padding）
- 色設定（Inbox: 青系、Desk: 琥珀系）
- レスポンシブ対応

### 7. 自動処理の仕組み

**バックグラウンドジョブは使用しません**。ユーザーアクセス時に処理を実行します。

#### 自動配達

- `DashboardController#deliver_scheduled_cards` で実行
- `scheduled_at <= Time.current` のカードを自動的に `arrived` 状態に更新
- ユーザーがダッシュボードにアクセスするたびに実行

#### 自動リセット

- `DashboardController#reset_desk_if_new_day` で実行
- `User.last_reset_date` と現在の日付を比較
- 日付が変わっていたら、机のカードを全てポストに戻す
- `last_reset_date` を更新

**メリット:**

- Solid Queue の設定・管理不要
- シンプルな実装
- リアルタイム（ジョブの待ち時間なし）
- 追加のプロセス起動不要

**注意点:**

- ユーザーがアクセスしないと処理されない（個人用アプリなので問題なし）

### 8. テスト実装（RSpec）

#### RSpec 設定

**ファイル**: `spec/rails_helper.rb`

```ruby
require 'shoulda/matchers'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # OmniAuth のモックを有効化
  OmniAuth.config.test_mode = true
end

# Shoulda Matchers設定
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

#### FactoryBot 設定

**ファイル**: `spec/factories/users.rb`

```ruby
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    provider { "google_oauth2" }
    uid { Faker::Alphanumeric.alphanumeric(number: 10) }
  end
end
```

**ファイル**: `spec/factories/cards.rb`

```ruby
FactoryBot.define do
  factory :card do
    association :user
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraph }
    scheduled_at { 1.week.from_now }
    status { :scheduled }

    trait :arrived do
      status { :arrived }
    end

    trait :on_desk do
      status { :on_desk }
    end
  end
end
```

#### モデルスペック

**ファイル**: `spec/models/user_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
  end

  describe 'associations' do
    it { should have_many(:cards).dependent(:destroy) }
  end

  describe '.find_or_create_from_auth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '12345',
        info: {
          email: 'test@example.com',
          name: 'Test User',
          image: 'http://example.com/avatar.jpg'
        }
      })
    end

    it 'creates a new user from auth hash' do
      expect { User.find_or_create_from_auth(auth_hash) }.to change(User, :count).by(1)
    end

    it 'finds existing user by provider and uid' do
      user = create(:user, provider: 'google_oauth2', uid: '12345')
      expect(User.find_or_create_from_auth(auth_hash)).to eq(user)
    end
  end
end
```

**ファイル**: `spec/models/card_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Card, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:scheduled_at) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.should_arrive' do
      it 'returns scheduled cards with past scheduled_at' do
        past_card = create(:card, user: user, scheduled_at: 1.day.ago, status: :scheduled)
        future_card = create(:card, user: user, scheduled_at: 1.day.from_now, status: :scheduled)

        expect(Card.should_arrive).to include(past_card)
        expect(Card.should_arrive).not_to include(future_card)
      end
    end
  end

  describe 'status transitions' do
    let(:card) { create(:card) }

    describe '#arrive!' do
      it 'changes status to arrived' do
        card.arrive!
        expect(card.status).to eq('arrived')
      end
    end

    describe '#move_to_desk!' do
      let(:card) { create(:card, :arrived) }

      it 'changes status to on_desk' do
        card.move_to_desk!
        expect(card.status).to eq('on_desk')
      end
    end

    describe '#snooze!' do
      let(:card) { create(:card) }
      let(:new_date) { 1.week.from_now }

      it 'reschedules the card' do
        card.snooze!(new_date)
        expect(card.status).to eq('scheduled')
        expect(card.scheduled_at).to be_within(1.second).of(new_date)
        expect(card.snoozed_count).to eq(1)
      end
    end
  end
end
```

#### コントローラースペック

**ファイル**: `spec/controllers/cards_controller_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe CardsController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'POST #create' do
    let(:card_params) do
      { title: 'New Card', content: 'Content', scheduled_at: 1.week.from_now }
    end

    it 'creates a new card' do
      expect {
        post :create, params: { card: card_params }
      }.to change(Card, :count).by(1)
    end

    it 'sets status to scheduled' do
      post :create, params: { card: card_params }
      expect(Card.last.status).to eq('scheduled')
    end
  end

  describe 'PATCH #keep' do
    let(:card) { create(:card, :arrived, user: user) }

    it 'moves card to desk' do
      patch :keep, params: { id: card.id }
      card.reload
      expect(card.status).to eq('on_desk')
    end
  end
end
```

#### サポートファイル

**ファイル**: `spec/support/auth_helper.rb`

```ruby
module AuthHelper
  def sign_in(user)
    session[:user_id] = user.id
  end

  def mock_auth_hash(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: user.provider,
      uid: user.uid,
      info: {
        email: user.email,
        name: user.name,
        image: user.avatar_url
      }
    })
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :controller
end
```

### MVP のゴール

以下が動作する状態：

1. ✅ Google でログイン
2. ✅ カードを作成して未来の日付で投函（画面から消える）
3. ✅ ダッシュボードアクセス時に配達予定のカードが自動配達される
4. ✅ ポストのカードを仕分け：Keep / Done / Snooze
5. ✅ Keep したカードは机に表示
6. ✅ 机のカードを完了できる
7. ✅ 日付が変わったら机のカードが自動的にポストに戻る
8. ✅ Turbo Streams でページ遷移なし
9. ✅ 基本的なテストが通る

---

## Phase 2: UI/UX 改善（MVP 後）

### 実装項目

1. **スタイリング強化**

   - カードデザイン改善（グラデーション、影、アイコン）
   - レスポンシブ対応（スマホ最適化）
   - ダークモード対応（オプション）

2. **アニメーション実装**

   - カード投函時の消失アニメーション
   - Keep 時の落下アニメーション（上 → 下）
   - Done 時のフェードアウト
   - カードスタック効果（重なり表示）

3. **インタラクション改善**

   - スワイプジェスチャー（モバイル対応）
   - ドラッグ&ドロップで並び替え（Sortable.js）
   - キーボードショートカット

4. **日付ピッカー改善**
   - Flatpickr 導入（importmap 経由）
   - 未来日付のみ選択可能
   - プリセット（明日、1 週間後、1 ヶ月後、1 年後）

### 重要ファイル

- `app/assets/stylesheets/application.tailwind.css`
- `app/javascript/controllers/card_controller.js`（スワイプ実装）
- `app/javascript/controllers/desk_controller.js`（Sortable 統合）

---

## Phase 3: 高度な機能（Phase 2 後）

### 実装項目

1. **タイムゾーン対応**

   - ユーザータイムゾーン設定（`users.time_zone`カラム追加）
   - リセット時刻をユーザータイムゾーンで計算
   - 設定画面でタイムゾーン選択

2. **アーカイブ・統計**

   - 完了カード一覧画面
   - 統計表示（完了数、スヌーズ率）
   - カレンダービュー（予定カード）

3. **検索・フィルター**

   - カード検索機能
   - ステータス別フィルター
   - 日付範囲フィルター

4. **パフォーマンス最適化**

   - N+1 クエリ解消（includes）
   - ページネーション（Pagy）
   - フラグメントキャッシュ

5. **通知機能（オプション）**
   - カード到着時のメール通知
   - Web Push 通知

---

## 実装の優先順位チェックリスト

### Phase 1 (MVP) - 必須

**セットアップ**

- [ ] Gemfile 更新（omniauth, omniauth-google-oauth2, omniauth-rails_csrf_protection, tailwindcss-rails, dotenv-rails, rspec-rails, factory_bot_rails, faker, shoulda-matchers）
- [ ] `bundle install`
- [ ] RSpec セットアップ（`rails generate rspec:install`）
- [ ] spec/rails_helper.rb に FactoryBot, Shoulda Matchers 設定追加
- [ ] Tailwind CSS 導入（`rails tailwindcss:install`）
- [ ] .env 作成（GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET）
- [ ] Google Cloud Console でプロジェクト・OAuth 設定
- [ ] omniauth.rb 作成（config/initializers/）

**データベース**

- [ ] User モデル・マイグレーション作成（provider, uid, last_reset_date を含む）
- [ ] Card モデル・マイグレーション作成
- [ ] `rails db:migrate`
- [ ] FactoryBot factories 作成（users.rb, cards.rb）

**認証**

- [ ] SessionsController 作成（new, create, destroy, failure）
- [ ] ApplicationController に認証ヘルパー追加
- [ ] ログイン画面作成（sessions/new.html.erb）
- [ ] ルート設定（認証関連）

**コントローラー・ビュー**

- [ ] DashboardController 作成
- [ ] CardsController 作成（create, keep, done, snooze, destroy）
- [ ] ルート設定（dashboard, cards）
- [ ] dashboard/index.html.erb 作成（上下 2 分割）
- [ ] cards/\_form.html.erb 作成（カード作成フォーム）
- [ ] cards/\_inbox_card.html.erb 作成
- [ ] cards/\_desk_card.html.erb 作成

**フロントエンド**

- [ ] card_controller.js 作成
- [ ] inbox_controller.js 作成
- [ ] form_controller.js 作成
- [ ] modal_controller.js 作成
- [ ] Tailwind 基本スタイル適用

**自動処理**

- [ ] DashboardController に自動配達処理追加（deliver_scheduled_cards）
- [ ] DashboardController に自動リセット処理追加（reset_desk_if_new_day）
- [ ] 自動処理のテスト作成

**テスト（RSpec）**

- [ ] spec/rails_helper.rb 設定（FactoryBot, OmniAuth mock）
- [ ] spec/support/auth_helper.rb 作成
- [ ] spec/factories/users.rb 作成
- [ ] spec/factories/cards.rb 作成
- [ ] spec/models/user_spec.rb 作成
- [ ] spec/models/card_spec.rb 作成
- [ ] spec/controllers/cards_controller_spec.rb 作成
- [ ] spec/controllers/dashboard_controller_spec.rb 作成（自動処理のテスト）
- [ ] `rspec` で全テスト通過確認

**動作確認**

- [ ] ローカルで rails server 起動
- [ ] Google ログイン成功
- [ ] カード作成・投函
- [ ] ダッシュボードアクセスでカード配達確認
- [ ] 仕分け動作（Keep/Done/Snooze）
- [ ] 日付変更後の自動リセット確認

### Phase 2 (UI/UX) - 重要

- [ ] アニメーション CSS 追加
- [ ] スワイプジェスチャー実装
- [ ] Sortable.js 導入
- [ ] Flatpickr 導入
- [ ] レスポンシブ対応

### Phase 3 (高度な機能) - オプション

- [ ] タイムゾーン対応（users.time_zone カラム追加、設定画面）
- [ ] アーカイブ画面
- [ ] 統計・検索機能
- [ ] パフォーマンス最適化（N+1 解消、ページネーション）

---

## Critical Files

実装で最も重要なファイル：

1. **`app/models/user.rb`** - ユーザーモデル（OAuth 認証、自動リセット日付管理）
2. **`app/models/card.rb`** - コアビジネスロジック（ステータス遷移）
3. **`app/controllers/dashboard_controller.rb`** - 自動配達・自動リセット処理
4. **`app/controllers/cards_controller.rb`** - カード操作の中心
5. **`app/views/dashboard/index.html.erb`** - メイン UI（上下 2 分割）
6. **`app/javascript/controllers/card_controller.js`** - フロントエンドインタラクション
7. **`config/routes.rb`** - ルート定義

---

## 開発サーバー起動手順

```bash
# ターミナル1: Railsサーバー
rails server

# ターミナル2: Tailwind CSS（watch mode）
rails tailwindcss:watch
```

ブラウザで http://localhost:3000 にアクセス

**注意**: バックグラウンドジョブを使用しないため、Solid Queue の起動は不要です

---

## トラブルシューティング

### OAuth 認証エラー

- リダイレクト URI が正しく設定されているか確認
- `.env` の CLIENT_ID/SECRET が正しいか確認
- `omniauth-rails_csrf_protection` gem がインストールされているか確認

### Turbo Streams が動作しない

- `Accept: text/vnd.turbo-stream.html` ヘッダーが送信されているか確認
- CSRF トークンが正しく送信されているか確認

### カードが自動配達されない

- ダッシュボードにアクセスしているか確認
- `scheduled_at` が過去の日時になっているか確認
- `log/development.log` でエラー確認

### 自動リセットが動作しない

- 日付が変わった後、ダッシュボードにアクセスしているか確認
- `User.last_reset_date` が正しく更新されているか確認

---

## 実装完了の定義

**MVP 完了条件:**

1. Google でログインできる
2. カードを未来の日付で投函できる（投函後、画面から消える）
3. ダッシュボードアクセス時に、scheduled_at が過ぎたカードが自動的にポストに配達される
4. ポストのカードを Keep / Done / Snooze できる
5. Keep したカードが机に表示される
6. 机のカードを完了できる
7. 日付が変わった後にダッシュボードアクセスすると、机のカードが自動的にポストに戻る
8. すべての操作が Turbo Streams でページ遷移なしで動作
9. 基本的なテストが通る（モデル、コントローラー、自動処理）

これが動作すれば、MVP は完成です！

---

## 技術的な補足

### なぜバックグラウンドジョブを使わないのか？

**理由:**

1. **シンプルさ**: Solid Queue の設定・管理が不要
2. **リアルタイム性**: ユーザーアクセス時に即座に処理される（ジョブの 5 分待ちがない）
3. **個人用アプリに適している**: ユーザーがアクセスしないと処理されないが、個人用なら問題なし
4. **コスト削減**: 追加のプロセスを起動する必要がない

**注意点:**

- ユーザーがアクセスしない限り処理されない
- 複数ユーザーが同時アクセスする場合、各ユーザーが自分のカードのみ処理する
- 大規模なサービスでは、バックグラウンドジョブの方が適切

### provider と uid の必要性

OmniAuth を使用する場合、`provider` と `uid` は標準的な構成です：

- **provider**: どの認証プロバイダーを使ったか（"google_oauth2", "github", etc.）
- **uid**: プロバイダーが提供するユーザー固有の ID

この 2 つの組み合わせで、同じユーザーを一意に識別します。例えば：

- Google で認証: `provider: "google_oauth2", uid: "12345"`
- 将来 GitHub を追加した場合: `provider: "github", uid: "67890"`

同じメールアドレスでも、プロバイダーが異なれば別のユーザーとして扱えます。
