RSpec.shared_context 'ログイン済みユーザー', shared_context: :metadata do
  let(:user) { create(:user, provider: 'google_oauth2', uid: '12345') }

  before do
    # OmniAuthのモックを設定
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '12345',
      info: {
        email: user.email,
        name: user.name
      }
    })

    # Google認証を実行
    visit '/auth/google_oauth2/callback'
  end
end
