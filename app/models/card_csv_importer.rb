class CardCsvImporter
  attr_reader :errors

  def initialize(user, file)
    @user = user
    @file = file
    @errors = []
  end

  def import
    # TODO: 実装
    true
  end
end
