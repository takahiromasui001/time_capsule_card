class DashboardController < ApplicationController
  def index
    @inbox_cards = current_user.cards.where(status: :arrived).order(created_at: :desc)
    @desk_cards = current_user.cards.where(status: :on_desk).order(position: :asc, created_at: :desc)
    @new_card = Card.new
  end
end
