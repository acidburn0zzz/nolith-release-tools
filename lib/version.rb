class Version < String
  def self.branch_name(version_string)
    new(version_string).branch_name
  end

  def self.patch?(version_string)
    new(version_string).patch?
  end

  def self.rc?(version_string)
    new(version_string).rc?
  end

  def self.release?(version_string)
    new(version_string).release?
  end

  def self.tag(version_string)
    new(version_string).tag
  end

  def self.to_minor(version_string)
    new(version_string).to_minor
  end

  def self.to_patch(version_string)
    new(version_string).to_patch
  end

  def self.valid?(version_string)
    new(version_string).valid?
  end

  def branch_name(force_ee: false)
    if force_ee || self.end_with?('-ee')
      to_minor.gsub('.', '-') + '-stable-ee'
    else
      to_minor.gsub('.', '-') + '-stable'
    end
  end

  def patch?
    release? && /\.(\d+)$/.match(self)[1].to_i > 0
  end

  def rc?
    self =~ /\A\d+\.\d+\.\d+\.rc\d+\z/
  end

  def release?
    self =~ /\A\d+\.\d+\.\d+\Z/
  end

  def tag
    "v#{self}"
  end

  def to_minor
    self.match(/\A\d+\.\d+/).to_s
  end

  def to_patch
    self.match(/\A\d+\.\d+\.\d+/).to_s
  end

  def valid?
    release? || rc?
  end
end
