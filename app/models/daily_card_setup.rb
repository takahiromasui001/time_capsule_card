class DailyCardSetup
  def initialize(user)
    @user = user
  end

  def run
    deliver_scheduled_cards

    return if @user.last_reset_date == Date.current

    reset_desk_cards
    @user.update!(last_reset_date: Date.current)
  end

  private

  def deliver_scheduled_cards
    @user.cards.should_arrive.update_all(status: 'arrived')
  end

  def reset_desk_cards
    @user.cards.where(status: :on_desk).update_all(status: 'arrived')
  end
end
