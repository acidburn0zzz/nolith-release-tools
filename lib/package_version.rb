class PackageVersion < String
  REGEXP = /\Agitlab-(?<edition>ce|ee)[-_](?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(ce|ee)\.(?<revision>\d+)(_(?<arch>amd64|armhf)|\.(?<distro>el\d+|sles\d+)\.(?<arch>x86_64))\.(?<pkgtype>deb|rpm)\z/

  def edition
    REGEXP.match(self)[:edition]
  end

  def major
    REGEXP.match(self)[:major]
  end

  def minor
    REGEXP.match(self)[:minor]
  end

  def patch
    REGEXP.match(self)[:patch]
  end

  def revision
    REGEXP.match(self)[:revision]
  end
end
