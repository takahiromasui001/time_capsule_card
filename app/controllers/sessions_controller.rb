class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  # ログイン画面
  def new
    # redirect_to dashboard_path if logged_in?
    # redirect_to dashboard_path
  end

  # Google OAuth コールバック
  def create
    auth = request.env['omniauth.auth']
    user = User.find_or_create_from_auth_hash(auth)
    session[:user_id] = user.id
    redirect_to root_path, notice: 'Successfully signed in!'
  end

  # ログアウト
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: 'Signed out successfully.'
  end
end
