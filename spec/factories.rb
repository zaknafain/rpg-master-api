# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:id)         { |n| 1000 + n }
    sequence(:name)       { |n| "Person #{n}" }
    sequence(:email)      { |n| "person_#{n}@example.com" }
    password              { 'foobar Z' }
    password_confirmation { 'foobar Z' }
    locale                { I18n.available_locales.sample }

    trait :admin do
      admin { true }
    end
  end

  factory :campaign do
    sequence(:id) { |n| 2000 + n }
    user          { FactoryBot.create(:user) }
    name          { FFaker::Movie.title }
    description   { FFaker::Lorem.sentences(15).join(' ') }
    is_public     { true }

    trait :with_elements do
      hierarchy_elements do
        %i[author_only for_all_players for_everyone].map do |visibility|
          association(:hierarchy_element, visibility: visibility)
        end
      end
    end

    trait :with_player do
      players { [association(:user)] }
    end

    trait :with_content do
      hierarchy_elements do
        %i[author_only for_all_players for_everyone].map do |visibility|
          association(:hierarchy_element, :with_content, visibility: visibility)
        end
      end
    end
  end

  factory :hierarchy_element do
    sequence(:id) { |n| 3000 + n }
    hierarchable  { FactoryBot.create(:campaign) }
    name          { FFaker::Music.genre }
    visibility    { %i[author_only for_all_players for_everyone].sample }
    description   { FFaker::Lorem.sentences((0..3).to_a.sample).join(' ') }

    trait :with_content do
      content_texts do
        %i[author_only for_all_players for_everyone].map do |visibility|
          association(:content_text, visibility: visibility)
        end
      end
    end
  end

  factory :content_text do
    sequence(:id)     { |n| 4000 + n }
    hierarchy_element { FactoryBot.create(:hierarchy_element) }
    content           { 'Hello World' }
    visibility        { %i[author_only for_all_players for_everyone].sample }
  end
end
