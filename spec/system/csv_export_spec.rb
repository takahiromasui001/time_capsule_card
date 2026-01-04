require 'rails_helper'

RSpec.describe 'CSV Export', type: :system do
  include_context 'ログイン済みユーザー'

  describe 'CSVエクスポート' do
    before do
      create(:card, user: user, title: 'Card 1', content: 'Content 1', scheduled_at: 1.day.ago, status: :arrived)
      create(:card, user: user, title: 'Card 2', content: 'Content 2', scheduled_at: 2.days.ago, status: :done)
    end

    it 'カード一覧ページにエクスポートボタンが表示される' do
      visit cards_arrived_index_path

      expect(page).to have_link('CSVエクスポート')
    end

    it 'CSVファイルをダウンロードできる' do
      visit cards_arrived_index_path
      click_link 'CSVエクスポート'

      expect(page.response_headers['Content-Type']).to include('text/csv')
      expect(page.response_headers['Content-Disposition']).to include('cards_')
      expect(page.response_headers['Content-Disposition']).to include('.csv')
    end

    it 'CSVに全カードの情報が含まれる' do
      visit cards_export_path(format: :csv)

      expect(page.body).to include('title,content,scheduled_at,status')
      expect(page.body).to include('Card 1')
      expect(page.body).to include('Card 2')
    end
  end
end
