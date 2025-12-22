require 'rails_helper'

RSpec.describe 'Done Cards', type: :system do
  include_context 'ログイン済みユーザー'

  describe '完了済みカード一覧' do
    before do
      create(:card, user: user, title: 'Scheduled Card', scheduled_at: 1.week.from_now, status: :scheduled)
      create(:card, user: user, title: 'Arrived Card', scheduled_at: 1.day.ago, status: :arrived)
      create(:card, user: user, title: 'On Desk Card', scheduled_at: 2.days.ago, status: :on_desk)
      create(:card, user: user, title: 'Done Card', scheduled_at: 3.days.ago, status: :done, completed_at: 1.day.ago)
    end

    it 'doneステータスのカードのみ表示される' do
      visit cards_done_index_path

      expect(page).to have_content('Done Cards')
      expect(page).to have_content('Done Card')
      expect(page).not_to have_content('Scheduled Card')
      expect(page).not_to have_content('Arrived Card')
      expect(page).not_to have_content('On Desk Card')
    end
  end
end
