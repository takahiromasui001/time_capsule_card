class CardsController < ApplicationController
  def create
    @card = current_user.cards.build(card_params)
    @card.status = :scheduled

    if @card.save
      head :ok
    else
      render turbo_stream: turbo_stream.replace('card_form_modal', partial: 'cards/form', locals: { card: @card })
    end
  end

  private

  def card_params
    params.require(:card).permit(:title, :content, :scheduled_at)
  end
end
