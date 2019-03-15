# frozen_string_literal: true

namespace :prepare do
  desc 'Prepare for a new monthly release'
  task :monthly, [:version] do |_t, args|
    version = get_version(args)

    raise "`#{version}` is not a monthly version!" unless version.monthly?

    service = ReleaseTools::Services::MonthlyPreparationService.new(version)

    service.create_label
    service.create_stable_branches

    # Create the monthly and RC1 task issues
    Rake::Task['monthly_issue'].execute(version: version)
    Rake::Task['patch_issue'].execute(version: version.to_rc(1))
  end

  desc 'Prepare the next security release'
  task :security do
    issue_task = Rake::Task['security_patch_issue']
    service = ReleaseTools::Services::SecurityPreparationService.new

    service.next_versions.each do |version|
      issue_task.execute(version: version)
    end
  end
end
