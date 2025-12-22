class Cards::DoneController < ApplicationController
  def index
    @cards = current_user.cards.status_done.order(completed_at: :desc)
  end
end
