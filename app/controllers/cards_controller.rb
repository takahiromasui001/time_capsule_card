class CardsController < ApplicationController
  def new
    @card = current_user.cards.build

    render turbo_stream: turbo_stream.replace('card_form_content', partial: 'cards/form_content', locals: { card: @card })
  end

  def create
    @card = current_user.cards.build(card_params)
    @card.status = :scheduled

    if @card.save
      head :ok
    else
      render turbo_stream: turbo_stream.replace('card_form_content', partial: 'cards/form_content', locals: { card: @card }), status: :unprocessable_entity
    end
  end

  def edit
    @card = current_user.cards.find(params[:id])

    render turbo_stream: turbo_stream.replace('card_form_content', partial: 'cards/form_content', locals: { card: @card })
  end

  def update
    @card = current_user.cards.find(params[:id])
    @card.assign_attributes(card_params)

    @card.status_scheduled! if @card.will_save_change_to_scheduled_at?

    if @card.save
      head :ok
    else
      render turbo_stream: turbo_stream.replace('card_form_content', partial: 'cards/form_content', locals: { card: @card }), status: :unprocessable_entity
    end
  end
  private

  def card_params
    params.require(:card).permit(:title, :content, :scheduled_at)
  end
end
