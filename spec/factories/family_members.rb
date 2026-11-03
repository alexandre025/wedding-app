FactoryBot.define do
  factory :family_member do
    family
    sequence(:first_name) { |n| "Mélanie#{n}" }
    age_group { FamilyMember::ADULT }

    trait :with_email do
      sequence(:email) { |n| "invite#{n}@exemple.fr" }
    end

    trait :baby do
      age_group { FamilyMember::BABY }
      no_alcohol { true }
    end

    trait :kid do
      age_group { FamilyMember::KID }
      no_alcohol { true }
    end

    trait :teen do
      age_group { FamilyMember::TEEN }
      no_alcohol { true }
    end

    trait :coming do
      attends { true }
    end

    trait :not_coming do
      attends { false }
    end

    trait :teetotal do
      no_alcohol { true }
    end

    trait :vegetarian do
      vegetarian { true }
    end

    trait :brunching do
      attends_brunch { true }
    end

    trait :runner do
      attends_run { true }
    end

    trait :with_allergies do
      allergies { "Arachides" }
    end
  end
end
