# frozen_string_literal: true

namespace :prepare do
  desc 'Prepare the next security release'
  task :security_release do
    issue_task = Rake::Task['security_patch_issue']
    service = ReleaseTools::Services::SecurityPreparationService.new

    service.next_versions.each do |version|
      issue_task.execute(version: version)
    end
  end
end
