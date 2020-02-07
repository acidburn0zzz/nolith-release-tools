# frozen_string_literal: true

module ReleaseTools
  class SecurityPatchIssue < PatchIssue
    def title
      "Security patch release: #{versions_title}"
    end

    def confidential?
      true
    end

    def labels
      super + ',security'
    end

    def critical?
      ReleaseTools::SharedStatus.critical_security_release?
    end

    def milestone_name
      versions.first.milestone_name
    end

    protected

    def template_path
      File.expand_path('../../templates/security_patch.md.erb', __dir__)
    end

    def versions_title
      versions.join(', ')
    end
  end
end
