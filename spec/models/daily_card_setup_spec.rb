require 'rails_helper'

RSpec.describe DailyCardSetup do
  describe '#run' do
    let(:user) { create(:user) }
    let(:setup) { DailyCardSetup.new(user) }

    context '日付が変わった場合' do
      before { user.update!(last_reset_date: 1.day.ago.to_date) }

      where(:initial_status, :scheduled_at, :expected_status) do
        [
          [:scheduled, 1.hour.ago, 'arrived'],
          [:scheduled, 1.day.from_now, 'scheduled'],
          [:on_desk, 1.week.from_now, 'arrived'],
          [:arrived, 1.week.from_now, 'arrived'],
          [:done, 1.week.from_now, 'done']
        ]
      end

      with_them do
        it 'ステータスが正しく更新される' do
          card = create(:card, user: user, status: initial_status, scheduled_at: scheduled_at)
          setup.run
          expect(card.reload.status).to eq(expected_status)
        end
      end

      it 'last_reset_dateを今日に更新する' do
        setup.run
        expect(user.reload.last_reset_date).to eq(Date.current)
      end

      it '他のユーザーのカードには影響しない' do
        other_user = create(:user)
        other_scheduled = create(:card, user: other_user, status: :scheduled, scheduled_at: 1.hour.ago)
        other_on_desk = create(:card, user: other_user, status: :on_desk)

        setup.run

        expect(other_scheduled.reload.status).to eq('scheduled')
        expect(other_on_desk.reload.status).to eq('on_desk')
      end
    end

    context '日付が変わっていない場合' do
      before { user.update!(last_reset_date: Date.current) }

      it '到着日時が過ぎたカードは到着する' do
        scheduled_card = create(:card, user: user, status: :scheduled, scheduled_at: 1.hour.ago)

        setup.run

        expect(scheduled_card.reload.status).to eq('arrived')
      end

      it '机上のカードはリセットされない' do
        desk_card = create(:card, user: user, status: :on_desk)

        setup.run

        expect(desk_card.reload.status).to eq('on_desk')
      end
    end

    context 'last_reset_dateがnilの場合' do
      before { user.update!(last_reset_date: nil) }

      it 'セットアップを実行する' do
        card = create(:card, user: user, status: :scheduled, scheduled_at: 1.hour.ago)

        setup.run

        expect(card.reload.status).to eq('arrived')
        expect(user.reload.last_reset_date).to eq(Date.current)
      end
    end
  end
end
