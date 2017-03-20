# Public: Parses a package filename to retrieve version information and metadata
class PackageVersion < String
  REGEXP = %r{
    \Agitlab-
    (?<edition>ce|ee)[-_]
    (?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(rc(?<rc>\d+)\.)?(ce|ee)\.
    (?<revision>\d+)
    (_(?<arch>amd64|armhf)|\.(?<distro>el\d+|sles\d+)\.(?<arch>x86_64))\.
    (?<pkgtype>deb|rpm)\z
  }x

  # Public: GitLab Edition
  #
  # Return either :ce or :ee
  def edition
    REGEXP.match(self)[:edition].to_sym
  end

  # Public: Arch
  #
  # Return :amd64, :armhf or :x86_64
  def arch
    REGEXP.match(self)[:arch].to_sym
  end

  # Public: Major version
  #
  # Returns the major version as an Integer
  def major
    REGEXP.match(self)[:major].to_i
  end

  # Public: Minor version
  #
  # Returns the minor version as an Integer
  def minor
    REGEXP.match(self)[:minor].to_i
  end

  # Public: Patch version
  #
  # Returns the patch version as an Integer
  def patch
    REGEXP.match(self)[:patch].to_i
  end

  # Public: Revision number
  #
  # Returns the revision number as an Integer
  def revision
    REGEXP.match(self)[:revision].to_i
  end

  # Public: RC number
  #
  # Returns the revision number as an Integer or nil if it is not an RC
  def rc
    rc = REGEXP.match(self)[:rc]
    rc.to_i unless rc.nil?
  end

  # Public: Is an Enterprise Edition version?
  #
  # Returns a Boolean
  def ee?
    edition == :ee
  end

  # Public: Is a Community Edition version?
  #
  # Returns a Boolean
  def ce?
    edition == :ce
  end

  # Public: Is RC version?
  #
  # Returns a Boolean
  def rc?
    !rc.nil?
  end
end
