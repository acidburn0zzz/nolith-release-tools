class PackageVersion < String
  REGEXP = /\Agitlab-(?<edition>ce|ee)[-_](?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(ce|ee)\.(?<revision>\d+)(_(?<arch>amd64|armhf)|\.(?<distro>el\d+|sles\d+)\.(?<arch>x86_64))\.(?<pkgtype>deb|rpm)\z/

  def edition
    REGEXP.match(self)[:edition].to_sym
  end

  def major
    REGEXP.match(self)[:major].to_i
  end

  def minor
    REGEXP.match(self)[:minor].to_i
  end

  def patch
    REGEXP.match(self)[:patch].to_i
  end

  def revision
    REGEXP.match(self)[:revision].to_i
  end

  def ee?
    edition == :ee
  end

  def ce?
    edition == :ce
  end
end
