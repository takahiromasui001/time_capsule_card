class Cards::DoneController < ApplicationController
  def index
    @pagy, @cards = pagy(current_user.cards.status_done.order(completed_at: :desc), limit: 2)
  end
end
