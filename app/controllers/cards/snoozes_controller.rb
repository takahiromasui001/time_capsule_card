class Cards::SnoozesController < ApplicationController
  def create
    @card = current_user.cards.find(params[:card_id])
    @card.update!(
      status: :scheduled,
      scheduled_at: params[:scheduled_at],
      snoozed_count: (@card.snoozed_count || 0) + 1
    )

    render turbo_stream: turbo_stream.remove(@card)
  end
end
