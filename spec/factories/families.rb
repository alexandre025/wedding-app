FactoryBot.define do
  factory :family do
    sequence(:name) { |n| "Melchior#{n}" }

    trait :answered do
      answered_at { 2.days.ago }
    end
  end
end
