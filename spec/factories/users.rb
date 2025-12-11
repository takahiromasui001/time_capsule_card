FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    provider { 'google_oauth2' }
    sequence(:uid) { |n| "uid_#{n}" }
  end
end
