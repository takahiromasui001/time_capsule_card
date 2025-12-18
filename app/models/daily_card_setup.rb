class DailyCardSetup
  def initialize(user)
    @user = user
  end

  def run
    return if @user.last_reset_date == Date.current

    deliver_scheduled_cards
    reset_desk_cards
    mark_setup_done
  end

  private

  def deliver_scheduled_cards
    @user.cards.should_arrive.update_all(status: 'arrived')
  end

  def reset_desk_cards
    @user.cards.where(status: :on_desk).update_all(status: 'arrived')
  end

  def mark_setup_done
    @user.update!(last_reset_date: Date.current)
  end
end
