module Slack
  module Channel
    def self.for(version)
      "#f_release_#{version.major}_#{version.minor}"
    end
  end
end
