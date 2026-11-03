FactoryBot.define do
  factory :family do
    sequence(:name) { |n| "Melchior#{n}" }

    trait :answered do
      after(:create) do |family|
        create(:family_member, :coming, family:)
        create(:family_member, :not_coming, family:)
      end
    end
  end
end
