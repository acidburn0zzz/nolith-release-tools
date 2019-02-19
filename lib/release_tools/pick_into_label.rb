# frozen_string_literal: true

module ReleaseTools
  class PickIntoLabel
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
