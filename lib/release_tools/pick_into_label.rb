# frozen_string_literal: true

module ReleaseTools
  class PickIntoLabel
    COLOR = '#00C8CA'
    DESCRIPTION = 'Merge requests to cherry-pick into the `%s` branch.'

    # Create a group label for the specified version
    def self.create(version)
      GitlabClient.create_group_label(
        Project::GitlabCe.group,
        self.for(version),
        COLOR,
        description: DESCRIPTION % version.stable_branch
      )
    end

    def self.escaped(version)
      CGI.escape(self.for(version))
    end

    def self.for(version)
      "Pick into #{version.to_minor}"
    end

    def self.reference(version)
      %[~"#{self.for(version)}"]
    end
  end
end
