class Card::DesksController < ApplicationController
  def create
    @card = current_user.cards.find(params[:card_id])
    @card.update!(status: :on_desk)

    render turbo_stream: [
      turbo_stream.remove(@card),
      turbo_stream.prepend('desk_cards', partial: 'cards/desk_card', locals: { desk_card: @card })
    ]
  end
end
