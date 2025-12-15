FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    provider { 'google_oauth2' }
    sequence(:uid) { |n| "uid_#{n}" }
  end
end
