require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  describe 'ダッシュボードページ' do
    context '未ログイン状態' do
      it 'ログインページにリダイレクトされる' do
        visit dashboard_path
        expect(page).to have_current_path(login_path)
        expect(page).to have_content('Please sign in')
      end
    end

    context 'ログイン状態' do
      include_context 'ログイン済みユーザー'

      before do
        visit dashboard_path
      end

      it 'ダッシュボードページが表示される' do
        expect(page).to have_current_path(dashboard_path)

        expect(page).to have_content('Post')
        expect(page).to have_content('届いたカードがここに表示されます')

        expect(page).to have_content('Today\'s Desk')
        expect(page).to have_content('保留したカードがここに表示されます')

        expect(page).to have_button('Logout')
      end
    end
  end
end
