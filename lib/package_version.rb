# Parses a package filename to retrieve version information and metadata
class PackageVersion < String
  REGEXP = /\Agitlab-(?<edition>ce|ee)[-_](?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(ce|ee)\.(?<revision>\d+)(_(?<arch>amd64|armhf)|\.(?<distro>el\d+|sles\d+)\.(?<arch>x86_64))\.(?<pkgtype>deb|rpm)\z/

  # GitLab Edition
  #
  # @return [Symbol] either :ce or :ee
  def edition
    REGEXP.match(self)[:edition].to_sym
  end

  # Major version
  #
  # @return [Integer] major version
  def major
    REGEXP.match(self)[:major].to_i
  end

  # Minor veersion
  #
  # @return [Integer] minor version
  def minor
    REGEXP.match(self)[:minor].to_i
  end

  # Patch version
  #
  # @return [Integer] patch version
  def patch
    REGEXP.match(self)[:patch].to_i
  end

  # Revision number
  #
  # @return [Integer] revision
  def revision
    REGEXP.match(self)[:revision].to_i
  end

  # Enterprise Edition version?
  #
  # @return [Boolean]
  def ee?
    edition == :ee
  end

  # Community Edition version?
  #
  # @return [Boolean]
  def ce?
    edition == :ce
  end
end
