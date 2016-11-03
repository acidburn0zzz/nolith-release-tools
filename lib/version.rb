class Version < String
  VERSION_REGEX = /\A\d+\.\d+\.\d+(-rc\d+)?(-ee)?\z/.freeze
  RELEASE_REGEX = /\A(\d+)\.(\d+)\.(\d+)\z/.freeze

  def ee?
    end_with?('-ee')
  end

  def milestone_name
    to_minor
  end

  def patch?
    patch > 0
  end

  def major
    return 0 unless version?

    @major ||= /\A(\d+)\./.match(self)[1].to_i
  end

  def minor
    return 0 unless version?

    @minor ||= /\A\d+\.(\d+)/.match(self)[1].to_i
  end

  def patch
    return 0 unless release?

    @patch ||= /\.(\d+)$/.match(self)[1].to_i
  end

  def rc
    match(/-(rc\d+)(-ee)?\z/).captures.first if rc?
  end

  def rc?
    self =~ /\A\d+\.\d+\.\d+-rc\d+(-ee)?\z/
  end

  def version?
    self =~ VERSION_REGEX
  end

  def release?
    self =~ RELEASE_REGEX
  end

  def next_minor
    captures = /\A(\d+)\.(\d+)/.match(self).captures

    "#{captures[0]}.#{captures[1].to_i + 1}.0"
  end

  def previous_patch
    return unless patch?

    captures = match(RELEASE_REGEX).captures

    "#{captures[0]}.#{captures[1]}.#{patch - 1}"
  end

  def next_patch
    return unless release?

    captures = match(RELEASE_REGEX).captures

    "#{captures[0]}.#{captures[1]}.#{patch + 1}"
  end

  def stable_branch(ee: false)
    to_minor.gsub('.', '-') << if ee || ee?
      '-stable-ee'
    else
      '-stable'
    end
  end

  def tag(ee: false)
    tag_for(self, ee: ee)
  end

  def previous_tag(ee: false)
    return unless patch?

    tag_for(previous_patch, ee: ee)
  end

  # Convert the current version to CE if it isn't already
  def to_ce
    return self unless ee?

    self.class.new(to_s.gsub(/-ee$/, ''))
  end

  # Convert the current version to EE if it isn't already
  def to_ee
    return self if ee?

    self.class.new("#{self}-ee")
  end

  def to_minor
    match(/\A\d+\.\d+/).to_s
  end

  def to_omnibus(ee: false)
    str = "#{to_patch}+"
    str << "#{rc}." if rc?
    str << (ee ? 'ee' : 'ce')
    str << '.0'
  end

  def to_patch
    match(/\A\d+\.\d+\.\d+/).to_s
  end

  def to_rc(number = 1)
    "#{to_patch}-rc#{number}"
  end

  def valid?
    release? || rc?
  end

  private

  def tag_for(version, ee: false)
    str = "v#{version}"
    str << '-ee' if ee && !ee?

    str
  end
end
