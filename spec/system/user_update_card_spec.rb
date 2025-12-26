require 'rails_helper'

RSpec.describe 'UserUpdateCard', type: :system do
  describe 'カード更新機能' do
    include_context 'ログイン済みユーザー'

    let!(:card) { create(:card, user: user, title: '元のタイトル', content: '元の内容', status: :on_desk) }

    before do
      visit dashboard_path
    end

    it 'ユーザーがフォームからカードを更新できる', :js do
      within("#card_#{card.id}") do
        find('a[href*="edit"]').click
      end

      within('#card_form_modal') do
        fill_in 'タイトル', with: '更新後のタイトル'
        fill_in '内容', with: '更新後の内容'

        click_button '投函する'
      end

      10.times do
        break if card.reload.title == '更新後のタイトル'
        sleep 1
      end

      expect(card.reload.title).to eq('更新後のタイトル')
      expect(card.reload.content).to eq('更新後の内容')
    end
  end
end
