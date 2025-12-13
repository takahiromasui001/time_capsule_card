class DashboardController < ApplicationController
  def index
    @inbox_cards = []
    @desk_cards = []
  end
end
