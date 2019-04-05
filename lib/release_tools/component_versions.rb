# frozen_string_literal: true

module ReleaseTools
  class ComponentVersions
    FILES = %w[GITALY_SERVER GITLAB_PAGES GITLAB_SHELL GITLAB_WORKHORSE].freeze

    def self.get(project, commit)
      versions = {}
      FILES.each do |x|
        versions["#{x}_VERSION"] = ReleaseTools::GitlabClient.file_contents(
          project.path,
          "#{x}_VERSION",
          commit.id
        ).chomp
      end

      versions
    end
  end
end
