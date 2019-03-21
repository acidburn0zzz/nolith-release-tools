# frozen_string_literal: true

namespace :release_managers do
  desc "Verify release manager authorization"
  task :auth, [:username] do |_t, args|
    unless args[:username].present?
      abort "You must provide a username to verify!"
    end

    unless ReleaseTools::ReleaseManagers::Definitions.allowed?(args[:username])
      abort "#{args[:username]} is not an authorized release manager!"
    end
  end

  desc "Sync Release Manager membership"
  task :sync do
    result = ReleaseTools::ReleaseManagers::Definitions.sync!

    unless result.success?
      $stdout.puts result.formatted_error_message
      exit 1
    end
  end
end
