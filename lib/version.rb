class Version
  class << self
    def valid?(version)
      release?(version) || rc?(version)
    end

    def branch_name(version)
      minor_version = version.match(/\A\d\.\d/).to_s
      minor_version.gsub('.', '-') + '-stable'
    end

    def release?(version)
      version =~ /\A\d\.\d\.\d\Z/
    end

    def rc?(version)
      version =~ /\A\d+\.\d+\.\d+\.rc\d+/
    end

    def tag(version)
      'v' + version
    end
  end
end
