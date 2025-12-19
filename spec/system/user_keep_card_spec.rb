require 'rails_helper'

RSpec.describe 'UserKeepCard', type: :system do
  include ActionView::RecordIdentifier

  describe 'カードKeep機能' do
    include_context 'ログイン済みユーザー'

    it 'ユーザーがカードをKeepできる', :js do
      card = create(:card, user: user, title: 'テストカード', content: 'テスト内容', status: :arrived)
      visit dashboard_path

      within("##{dom_id(card)}") do
        expect(page).to have_content('テストカード')
        click_button 'Keep'
      end

      expect(page).to have_no_css("#inbox_cards ##{dom_id(card)}")
      expect(page).to have_css("#desk_cards ##{dom_id(card)}")
      expect(card.reload.status).to eq('on_desk')
    end
  end
end
