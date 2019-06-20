# frozen_string_literal: true

namespace :maintainers do
  namespace :gitaly do
    desc 'Check if the user is a maintainer'
    task :auth, [:username] do |_t, args|
      username = args[:username]
      unless username.present?
        abort "You must provide a username to verify!"
      end

      unless ReleaseTools::Maintainer.project_maintainer?(username, ReleaseTools::Project::Gitaly)
        abort "#{username} is not a maintainer!"
      end
    end
  end
end
