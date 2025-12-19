require 'rails_helper'

RSpec.describe 'UserArchiveCard', type: :system do
  include ActionView::RecordIdentifier

  describe 'カードArchive機能' do
    include_context 'ログイン済みユーザー'

    it 'ユーザーがカードをDoneできる', :js do
      card = create(:card, user: user, title: 'テストカード', content: 'テスト内容', status: :arrived)
      visit dashboard_path

      within("##{dom_id(card)}") do
        expect(page).to have_content('テストカード')
        click_button 'Done'
      end

      expect(page).to have_no_css("##{dom_id(card)}")
      expect(card.reload.status).to eq('done')
      expect(card.reload.completed_at).to be_present
    end
  end
end
