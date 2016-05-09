class Version < String

  VERSION_REGEX = /\A\d+\.\d+\.\d+(-rc\d+)?(-ee)?\z/.freeze
  RELEASE_REGEX = /\A(\d+\.\d+\.)(\d+)\z/.freeze

  def ee?
    self.end_with?('-ee')
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
    self.match(/-(rc\d+)(-ee)?\z/).captures.first if rc?
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

  def previous_patch
    return unless patch?

    captures = self.match(RELEASE_REGEX).captures

    "#{captures[0]}#{patch - 1}"
  end

  def next_patch
    return unless release?

    captures = self.match(RELEASE_REGEX).captures

    "#{captures[0]}#{patch + 1}"
  end

  def stable_branch(ee: false)
    to_minor.gsub('.', '-') << if ee || self.ee?
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

  private

  def tag_for(version, ee: false)
    str = "v#{version}"
    str << '-ee' if ee && !ee?

    str
  end
end
