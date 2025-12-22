class Cards::ArrivedController < ApplicationController
  def index
    @cards = current_user.cards
                         .where(status: [:arrived, :on_desk])
                         .order(scheduled_at: :desc)
  end
end
