FactoryBot.define do

  factory :enumeration do
    name 'TestEnum'

    trait :default do
      name 'Default'
      is_default true
    end
  end

  # not an enumeration, but same behaviour
  factory :issue_status, :class => 'IssueStatus' do
    sequence(:name){ |n| "TestStatus-#{n}"  }
    default_done_ratio 100

    trait :closed do
      is_closed true
    end
  end

  factory :issue_priority, :parent => :enumeration, :class => 'IssuePriority' do
    name 'TestPriority'
  end

  factory :issue_category do
    sequence(:name){ |n| "Issue category ##{n}" }
    project
  end

  factory :issue do
    transient do
      factory_is_child false
    end

    sequence(:subject) { |n| "Test issue ##{n}" }
    estimated_hours 4

    project
    tracker { project.trackers.first }
    start_date { Date.today }
    due_date { Date.today + 7.days }
    status { tracker.default_status }
    priority { IssuePriority.default || FactoryBot.create(:issue_priority, :default) }
    association :author, :factory => :user, :firstname => "Author"
    association :assigned_to, :factory => :user, :firstname => "Assignee"

    trait :child_issue do
      factory_is_child true
    end

    trait :reccuring do
      easy_is_repeating true
      easy_repeat_settings Hash[ 'period' => 'daily', 'daily_option' => 'each', 'daily_each_x' => '1', 'endtype' => 'endless', 'create_now' => 'none' ]
    end

    trait :reccuring_monthly do
      easy_is_repeating true
      easy_repeat_settings Hash[ 'period' => 'monthly', 'monthly_option' => 'xth', 'monthly_period' => '1', 'monthly_day' => (Date.today + 3.days).mday, 'endtype' => 'endless', 'create_now' => 'none' ]
    end

    trait :with_version do
      association :fixed_version, factory: :version
    end

    trait :with_journals do
      after(:create) do |issue|
        FactoryBot.create_list(:journal, 2, issue: issue, journalized_type: 'Issue')
      end
    end

    trait :with_description do
      sequence(:description) { |n| "Description ##{n}" }
    end

    trait :with_attachment do
      after(:create) do |issue|
        FactoryBot.create_list(:attachment, 1, container: issue)
      end
    end

    trait :with_short_url

    after :build do |issue, evaluator|
      if evaluator.factory_is_child
        issue.parent_issue_id = FactoryBot.create(:issue, :project => issue.project).id
      end
    end
  end

  factory :journal do
    sequence(:notes) { |n| "Notes #{n}" }
    journalized_type 'Issue'
  end

end
