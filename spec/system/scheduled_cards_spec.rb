require 'rails_helper'

RSpec.describe 'Scheduled Cards', type: :system do
  include_context 'ログイン済みユーザー'

  describe '投函済みカード一覧' do
    before do
      create(:card, user: user, title: 'Scheduled Card', scheduled_at: 1.week.from_now, status: :scheduled)
      create(:card, user: user, title: 'Arrived Card', scheduled_at: 1.day.ago, status: :arrived)
      create(:card, user: user, title: 'On Desk Card', scheduled_at: 2.days.ago, status: :on_desk)
      create(:card, user: user, title: 'Done Card', scheduled_at: 3.days.ago, status: :done)
    end

    it 'scheduledステータスのカードのみ表示される' do
      visit cards_scheduled_index_path

      expect(page).to have_content('Scheduled Cards')
      expect(page).to have_content('Scheduled Card')
      expect(page).not_to have_content('Arrived Card')
      expect(page).not_to have_content('On Desk Card')
      expect(page).not_to have_content('Done Card')
    end
  end
end
