class Card::ArchivesController < ApplicationController
  def create
    @card = current_user.cards.find(params[:card_id])
    @card.update!(status: :done, completed_at: Time.current)

    render turbo_stream: turbo_stream.remove(@card)
  end
end
