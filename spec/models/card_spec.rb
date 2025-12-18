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
    it { should define_enum_for(:status).with_values(scheduled: 0, arrived: 10, on_desk: 20, done: 30).with_prefix(:status) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.should_arrive' do
      it 'scheduled_atが過去のscheduledステータスのカードを返す' do
        past_card = create(:card, user: user, status: :scheduled, scheduled_at: 1.day.ago)
        future_card = create(:card, user: user, status: :scheduled, scheduled_at: 1.day.from_now)
        arrived_card = create(:card, user: user, status: :arrived, scheduled_at: 1.day.ago)

        expect(Card.should_arrive).to include(past_card)
        expect(Card.should_arrive).not_to include(future_card)
        expect(Card.should_arrive).not_to include(arrived_card)
      end
    end
  end
end
