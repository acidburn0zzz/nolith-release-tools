class Version < String
  def ee?
    self.end_with?('-ee')
  end

  def milestone_name
    to_minor
  end

  def patch?
    release? && /\.(\d+)$/.match(self)[1].to_i > 0
  end

  def rc
    self.match(/[\.-](rc\d+)\z/).captures.first if rc?
  end

  def rc?
    self =~ /\A\d+\.\d+\.\d+[\.-]rc\d+\z/
  end

  def release?
    self =~ /\A\d+\.\d+\.\d+\Z/
  end

  def stable_branch(ee: false)
    if ee || self.ee?
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

  def to_omnibus(ee: false)
    str = "#{to_patch}+"
    str << "#{rc}." if rc?
    str << (ee ? 'ee' : 'ce')
    str << '.0'
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
