class DashboardController < ApplicationController
  before_action :daily_card_setup

  def index
    @inbox_cards = current_user.cards.where(status: :arrived).order(created_at: :desc)
    @desk_cards = current_user.cards.where(status: :on_desk).order(position: :asc, created_at: :desc)
    @new_card = Card.new
  end

  private

  def daily_card_setup
    DailyCardSetup.new(current_user).run
  end
end
