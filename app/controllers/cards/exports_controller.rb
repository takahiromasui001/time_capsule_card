require 'csv'

class Cards::ExportsController < ApplicationController
  def show
    cards = current_user.cards.order(created_at: :desc)
    send_data generate_csv(cards),
              filename: "cards_#{Date.current}.csv",
              type: :csv
  end

  private

  def generate_csv(cards)
    CSV.generate do |csv|
      csv << %w[title content scheduled_at status]
      cards.each do |card|
        csv << [card.title, card.content, card.scheduled_at, card.status]
      end
    end
  end
end
