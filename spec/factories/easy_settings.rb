FactoryBot.define do
  factory :easy_setting do

    name 'my_setting'
    value 'my_value'
    project

    trait :global do
      value 'my_global_value'
      project nil
    end
  end

end
