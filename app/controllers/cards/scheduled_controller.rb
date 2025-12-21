class Cards::ScheduledController < ApplicationController
  def index
    @cards = current_user.cards.status_scheduled.order(scheduled_at: :asc)
  end
end
