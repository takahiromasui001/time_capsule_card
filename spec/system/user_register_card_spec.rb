require 'rails_helper'

RSpec.describe 'UserRegisterCard', type: :system do
  describe 'カード登録機能' do
    include_context 'ログイン済みユーザー'

    before do
      visit dashboard_path
    end

    it 'ユーザーがフォームからカードを登録できる', :js do
      expect(page).to have_link('+')

      find('a', text: '+').click

      within('#card_form_modal') do
        expect(page).to have_content('新しいカードを投函')

        fill_in 'タイトル', with: '未来への手紙'
        fill_in '内容', with: '1年後の自分へのメッセージです'

        scheduled_time = 1.week.from_now
        page.execute_script("document.querySelector('#card_form_modal input[name=\"card[scheduled_at]\"]').value = '#{scheduled_time.strftime('%Y-%m-%dT%H:%M')}'")
        page.execute_script("document.querySelector('#card_form_modal input[name=\"card[scheduled_at]\"]').dispatchEvent(new Event('input', { bubbles: true }))")

        click_button '投函する'
      end

      # カードが保存されるまで待機（最大10秒）
      10.times do
        break if user.cards.reload.count == 1
        sleep 1
      end

      expect(user.cards.reload.count).to eq(1)
      expect(user.cards.last.title).to eq('未来への手紙')
      expect(user.cards.last.content).to eq('1年後の自分へのメッセージです')
      expect(user.cards.last.status).to eq('scheduled')
    end
  end
end
