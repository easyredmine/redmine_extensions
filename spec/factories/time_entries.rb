FactoryBot.define do

  factory :time_entry_activity, :parent => :enumeration, :class => 'TimeEntryActivity' do
    name 'TestActivity'
    initialize_with { TimeEntryActivity.find_or_create_by(name: name)}
    factory :default_time_entry_activity, :traits => [:default]
  end

  factory :time_entry do
    hours 1
    spent_on { Date.today - 1.month }

    issue
    project { issue.project }
    user
    association :activity, :factory => :default_time_entry_activity

    trait :current do
      spent_on { Date.today }
    end

    trait :old do
      spent_on { Date.today - 7.days }
    end

    trait :future do
      spent_on { Date.today + 70.days }
    end
  end

  factory :easy_global_time_entry_setting do
    spent_on_limit_before_today 2
    spent_on_limit_before_today_edit 5
    spent_on_limit_after_today 20
    spent_on_limit_after_today_edit 30
  end

end
