require 'rails_helper'

RSpec.describe 'UserUpdateScheduledCard', type: :system do
  describe 'Scheduledページでのカード編集機能' do
    include_context 'ログイン済みユーザー'

    let!(:card) { create(:card, user: user, title: '元のタイトル', content: '元の内容', status: :scheduled, scheduled_at: 1.week.from_now) }

    before do
      visit cards_scheduled_index_path
    end

    it 'ユーザーがScheduledページからカードを編集できる', :js do
      find('a[href*="edit"]').click

      within('#card_form_modal') do
        expect(page).to have_field('タイトル')

        fill_in 'タイトル', with: '', fill_options: { clear: :backspace }
        fill_in 'タイトル', with: '更新後のタイトル'
        fill_in '内容', with: '更新後の内容'

        click_button '投函する'
      end

      expect(page).to have_content('更新後のタイトル')
      expect(page).to have_content('更新後の内容')
    end
  end
end
