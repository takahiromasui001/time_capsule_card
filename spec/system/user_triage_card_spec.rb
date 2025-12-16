require 'rails_helper'

RSpec.describe 'UserTriageCard', type: :system do
  include ActionView::RecordIdentifier

  describe 'カードトリアージ機能' do
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

    it 'ユーザーがカードをSnoozeできる', :js do
      card = create(:card, user: user, title: 'テストカード', content: 'テスト内容', status: :arrived)
      visit dashboard_path

      within("##{dom_id(card)}") do
        expect(page).to have_content('テストカード')
        click_button 'Snooze'
      end

      within("#snooze-form-#{card.id}") do
        scheduled_time = 1.week.from_now
        page.execute_script("document.querySelector('input[name=\"scheduled_at\"]').value = '#{scheduled_time.strftime('%Y-%m-%dT%H:%M')}'")

        click_button '設定'
      end

      expect(page).to have_no_css("#inbox_cards ##{dom_id(card)}")
      expect(card.reload.status).to eq('scheduled')
      expect(card.reload.snoozed_count).to eq(1)
    end
  end
end
