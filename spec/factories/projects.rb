FactoryBot.define do
  factory :project do
    transient do
      number_of_issues 0
      number_of_members 0
      number_of_issue_categories 2
      number_of_subprojects 0
      add_modules []
      members []
      trackers []
      create_trackers false
    end
    # name 'Test project'
    sequence(:name){ |n| "Project ##{n}" }
    sequence(:identifier){ |n| "#{name.parameterize}#{n}" }

    after(:create) do |project, evaluator|
      trackers = Array.wrap(evaluator.trackers)
      trackers = Tracker.all.to_a if trackers.empty?
      trackers.concat( [FactoryBot.create(:tracker), FactoryBot.create(:bug_tracker)] ) if evaluator.create_trackers || trackers.empty?
      project.trackers = trackers
      project.time_entry_activities = [FactoryBot.create(:time_entry_activity)]
    end
    after :create do |project, evaluator|
      FactoryBot.create_list :issue, evaluator.number_of_issues, :project => project
      FactoryBot.create_list :member, evaluator.number_of_members, :project => project, :roles => [FactoryBot.create(:role)]
      project.enabled_module_names += evaluator.add_modules
    end

    after :create do |project, evaluator|
      evaluator.members.each do |user|
        FactoryBot.create(:member, project: project, user: user)
      end
    end

    trait :with_milestones do
      transient do
        number_of_versions 3
        milestone_options Hash.new
      end
      after :create do |project, evaluator|
        FactoryBot.create_list :version, evaluator.number_of_versions, evaluator.milestone_options.merge( :project => project )
      end
    end

    trait :with_subprojects do
      after :create do |project, evaluator|
        FactoryBot.create_list :project, evaluator.number_of_subprojects, :parent => project
      end
    end

    trait :with_categories do
      after :create do |project, evaluator|
        FactoryBot.create_list :issue_category, evaluator.number_of_issue_categories, :project => project
      end
    end
  end

  factory :role do
    sequence(:name){ |n| "Role ##{n}" }
    permissions { Role.new.setable_permissions.collect(&:name).uniq }
  end

  factory :member_role do
    role
    member
  end

  factory :member do
    project
    user

    after :build do |member, evaluator|
      member.member_roles << FactoryBot.build(:member_role, member: member)
    end

    trait :without_roles do
      after :create do |member, evaluator|
        member.member_roles.clear
      end
    end
  end

end
