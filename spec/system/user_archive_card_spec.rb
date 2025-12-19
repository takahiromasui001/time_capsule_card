require 'rails_helper'

RSpec.describe 'UserArchiveCard', type: :system do
  include ActionView::RecordIdentifier

  describe 'カードArchive機能' do
    include_context 'ログイン済みユーザー'

    it 'ユーザーが投函箱のカードをDoneできる', :js do
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

    it 'ユーザーが机のカードをDoneできる', :js do
      card = create(:card, user: user, title: '机のカード', content: 'テスト内容', status: :on_desk)
      visit dashboard_path

      within("##{dom_id(card)}") do
        expect(page).to have_content('机のカード')
        click_button 'Done'
      end

      expect(page).to have_no_css("##{dom_id(card)}")
      expect(card.reload.status).to eq('done')
      expect(card.reload.completed_at).to be_present
    end
  end
end
