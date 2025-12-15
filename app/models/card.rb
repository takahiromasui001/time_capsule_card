class Card < ApplicationRecord
  belongs_to :user

  enum :status, {
    scheduled: 0,   # 未来に投函済み（非表示）
    arrived: 10,    # ポストに到着
    on_desk: 20,    # 机の上
    done: 30        # 完了
  }, prefix: true

  validates :title, presence: true, length: { maximum: 200 }
  validates :scheduled_at, presence: true
end
