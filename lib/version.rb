class Version
  class << self
    def valid?(version)
      version =~ /\A\d\.\d\.\d\Z/
    end

    def branch_name(version)
      minor_version = version.match(/\A\d\.\d/).to_s
      minor_version.gsub('.', '-') + '-stable'
    end

    def rc1(version)
      version + '.rc1'
    end

    def tag_rc1(version)
      'v' + rc1(version)
    end

    def minor_release?(version)
      version =~ /\A\d\.\d\.0\Z/
    end
  end
end
