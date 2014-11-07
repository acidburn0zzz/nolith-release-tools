class Version
  def self.valid?(version)
    version =~ /\A\d\.\d\.\d\Z/
  end

  def self.branch_name(version)
    minor_version = version.match(/\A\d\.\d/).to_s
    minor_version.gsub('.', '-') + '-stable'
  end

  def self.rc1(version)
    version + '.rc1'
  end

  def self.tag_rc1(version)
    'v' + rc1(version)
  end
end
