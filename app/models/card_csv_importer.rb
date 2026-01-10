require 'csv'

class CardCsvImporter
  attr_reader :errors

  def initialize(user, file)
    @user = user
    @file = file
    @errors = []
  end

  def import
    return false unless valid_file?

    cards = build_cards
    return false if @errors.any?

    Card.transaction do
      cards.each(&:save!)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def valid_file?
    if @file.blank?
      @errors << 'ファイルを選択してください'
      return false
    end
    true
  end

  def build_cards
    cards = []
    CSV.foreach(@file.path, headers: true).with_index(2) do |row, line|
      card = @user.cards.build(
        title: row['title'],
        content: row['content'],
        scheduled_at: row['scheduled_at'],
        status: parse_status(row['status'])
      )
      unless card.valid?
        @errors << "行#{line}: #{card.errors.full_messages.join(', ')}"
      end
      cards << card
    end
    cards
  end

  def parse_status(value)
    return value if Card.statuses.key?(value)

    Card.statuses.key(value.to_i) || 'scheduled'
  end
end
