namespace :cards do
  desc '指定したユーザーのカードサンプルデータを作成 (例: EMAIL=user@example.com bin/rails cards:seed)'
  task seed: :environment do
    email = ENV['EMAIL']
    abort 'Usage: EMAIL=user@example.com bin/rails cards:seed' if email.blank?

    user = User.find_by(email: email)
    abort "User not found: #{email}" unless user

    # 到着済みカード（inbox）
    user.cards.create!(
      title: '今日のタスク',
      content: 'これは今日届いたカードです',
      scheduled_at: 1.day.ago,
      status: :arrived
    )

    user.cards.create!(
      title: '読書リスト確認',
      content: '今月読みたい本をリストアップする',
      scheduled_at: 2.days.ago,
      status: :arrived
    )

    # 机の上のカード（desk）
    user.cards.create!(
      title: 'プロジェクト企画書作成',
      content: '新規プロジェクトの企画書をまとめる',
      scheduled_at: 3.days.ago,
      status: :on_desk,
      position: 1
    )

    # スケジュール済み（未来のカード）
    user.cards.create!(
      title: '来週のミーティング準備',
      content: '資料を準備しておく',
      scheduled_at: 7.days.from_now,
      status: :scheduled
    )

    # 完了済みカード
    user.cards.create!(
      title: '先週のレビュー',
      content: '完了したタスクです',
      scheduled_at: 10.days.ago,
      status: :done,
      completed_at: 2.days.ago
    )

    puts "Created 5 sample cards for #{user.email}"
  end
end
