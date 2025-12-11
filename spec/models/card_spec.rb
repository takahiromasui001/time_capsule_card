require 'rails_helper'

RSpec.describe Card, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_presence_of(:scheduled_at) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(scheduled: 0, arrived: 10, on_desk: 20, done: 30) }
  end
end
