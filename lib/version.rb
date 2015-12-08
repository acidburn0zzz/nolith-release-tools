class Version < String
  def self.branch_name(version)
    new(version).branch_name
  end

  def self.rc?(version)
    new(version).rc?
  end

  def self.release?(version)
    new(version).release?
  end

  def self.tag(version)
    new(version).tag
  end

  def self.to_minor(version)
    new(version).to_minor
  end

  def self.valid?(version)
    new(version).valid?
  end

  def branch_name(force_ee: false)
    if force_ee || self.end_with?('-ee')
      to_minor.gsub('.', '-') + '-stable-ee'
    else
      to_minor.gsub('.', '-') + '-stable'
    end
  end

  def rc?
    self =~ /\A\d+\.\d+\.\d+\.rc\d+/
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

  def valid?
    release? || rc?
  end
end
