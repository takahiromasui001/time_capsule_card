class Card::TriagesController < ApplicationController
  def create
    @card = current_user.cards.find(params[:card_id])

    case params[:destination]
    when 'desk'
      @card.update!(status: :on_desk)
      render turbo_stream: [
        turbo_stream.remove(@card),
        turbo_stream.prepend('desk_cards', partial: 'cards/desk_card', locals: { desk_card: @card })
      ]
    when 'archive'
      @card.update!(status: :done, completed_at: Time.current)
      render turbo_stream: turbo_stream.remove(@card)
    when 'scheduled'
      @card.update!(
        status: :scheduled,
        scheduled_at: params[:scheduled_at],
        snoozed_count: (@card.snoozed_count || 0) + 1
      )
      render turbo_stream: turbo_stream.remove(@card)
    end
  end
end
