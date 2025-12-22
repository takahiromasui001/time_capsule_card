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

      expect(page).to have_content('Scheduled Card')
      expect(page).not_to have_content('Arrived Card')
      expect(page).not_to have_content('On Desk Card')
      expect(page).not_to have_content('Done Card')
    end
  end

  describe '期間フィルター' do
    before do
      create(:card, user: user, title: 'Within Week', scheduled_at: 3.days.from_now, status: :scheduled)
      create(:card, user: user, title: 'Within Month', scheduled_at: 2.weeks.from_now, status: :scheduled)
      create(:card, user: user, title: 'Within Quarter', scheduled_at: 2.months.from_now, status: :scheduled)
      create(:card, user: user, title: 'Later Card', scheduled_at: 4.months.from_now, status: :scheduled)
    end

    where(:period, :visible, :hidden) do
      [
        ['week', ['Within Week'], ['Within Month', 'Within Quarter', 'Later Card']],
        ['month', ['Within Month'], ['Within Week', 'Within Quarter', 'Later Card']],
        ['quarter', ['Within Quarter'], ['Within Week', 'Within Month', 'Later Card']],
        ['later', ['Later Card'], ['Within Week', 'Within Month', 'Within Quarter']]
      ]
    end

    with_them do
      it '該当期間のカードのみ表示される' do
        visit cards_scheduled_index_path(period: period)

        visible.each { |title| expect(page).to have_content(title) }
        hidden.each { |title| expect(page).not_to have_content(title) }
      end
    end
  end
end
