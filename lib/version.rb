class Version < String
  def self.patch?(version_string)
    new(version_string).patch?
  end

  def self.rc?(version_string)
    new(version_string).rc?
  end

  def self.release?(version_string)
    new(version_string).release?
  end

  def self.stable_branch(version_string)
    new(version_string).stable_branch
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

  def self.to_rc(version_string, number = 1)
    new(version_string).to_rc(number)
  end

  def self.valid?(version_string)
    new(version_string).valid?
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

  def stable_branch(ee: false)
    if ee || self.end_with?('-ee')
      to_minor.gsub('.', '-') << '-stable-ee'
    else
      to_minor.gsub('.', '-') << '-stable'
    end
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

  def to_rc(number = 1)
    "#{to_patch}-rc#{number}"
  end

  def valid?
    release? || rc?
  end
end
