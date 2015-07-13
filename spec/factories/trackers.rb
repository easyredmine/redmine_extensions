FactoryGirl.define do

  factory :tracker do
    sequence(:name) {|n| "Feature ##{n}"}

    default_status { IssueStatus.first || FactoryGirl.create(:issue_status) }

    trait :bug do
      sequence(:name) {|n| "Bug ##{n}"}
    end

    factory :bug_tracker, :traits => [:bug]
  end

end
