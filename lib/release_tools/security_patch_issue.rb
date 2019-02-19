# frozen_string_literal: true

module ReleaseTools
  class SecurityPatchIssue < PatchIssue
    def confidential?
      true
    end

    def labels
      super + ',security'
    end

    protected

    def template_path
      File.expand_path('../../templates/security_patch.md.erb', __dir__)
    end
  end
end
