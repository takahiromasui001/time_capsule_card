FactoryBot.define do
  factory :card do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    content { Faker::Lorem.paragraph }
    scheduled_at { 1.week.from_now }
    status { :scheduled }
  end
end
