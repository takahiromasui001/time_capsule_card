require 'rails_helper'

RSpec.describe 'UserSnoozeCard', type: :system do
  include ActionView::RecordIdentifier

  describe 'カードSnooze機能' do
    include_context 'ログイン済みユーザー'

    let(:card) { create(:card, user:, title: 'テストカード', status:) }

    before { card }

    context 'Inboxからスヌーズする場合' do
      let(:status) { :arrived }

      it 'カードをSnoozeできる', :js do
        visit dashboard_path

        within("#inbox_cards ##{dom_id(card)}") do
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

    context 'Deskからスヌーズする場合' do
      let(:status) { :on_desk }

      it 'カードを再Snoozeできる', :js do
        visit dashboard_path

        within("#desk_cards ##{dom_id(card)}") do
          click_button 'Snooze'
        end

        within("#snooze-form-#{card.id}") do
          scheduled_time = 1.week.from_now
          page.execute_script("document.querySelector('input[name=\"scheduled_at\"]').value = '#{scheduled_time.strftime('%Y-%m-%dT%H:%M')}'")
          click_button '設定'
        end

        expect(page).to have_no_css("#desk_cards ##{dom_id(card)}")
        expect(card.reload.status).to eq('scheduled')
      end
    end
  end
end
