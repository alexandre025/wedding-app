FactoryBot.define do
  factory :family_member do
    family
    sequence(:first_name) { |n| "Mélanie#{n}" }

    trait :with_email do
      sequence(:email) { |n| "invite#{n}@exemple.fr" }
    end
  end
end
