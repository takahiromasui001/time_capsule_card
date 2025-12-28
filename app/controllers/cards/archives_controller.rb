class Cards::ArchivesController < ApplicationController
  def create
    @card = current_user.cards.find(params[:card_id])
    @card.update!(status: :done, completed_at: Time.current)

    render turbo_stream: [
      turbo_stream.remove(@card),
      turbo_stream.append('toast_container', partial: 'shared/undo_toast', locals: { card: @card })
    ]
  end

  def destroy
    @card = current_user.cards.find(params[:card_id])
    @card.update!(status: :on_desk, completed_at: nil)

    render turbo_stream: [
      turbo_stream.prepend('desk_cards', partial: 'cards/desk_card', locals: { desk_card: @card }),
      turbo_stream.remove('undo_toast')
    ]
  end
end
