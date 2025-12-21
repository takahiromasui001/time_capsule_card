class Cards::ScheduledController < ApplicationController
  def index
    @cards = current_user.cards
                         .status_scheduled
                         .where(scheduled_at: period_range)
                         .order(scheduled_at: :asc)
    @current_period = params[:period] || 'week'
  end

  private

  def period_range
    case params[:period]
    when 'week'
      Time.current..1.week.from_now
    when 'month'
      1.week.from_now..1.month.from_now
    when 'quarter'
      1.month.from_now..3.months.from_now
    when 'later'
      3.months.from_now..
    else
      Time.current..1.week.from_now
    end
  end
end
