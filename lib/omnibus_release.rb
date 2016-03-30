require_relative 'release'
require_relative 'omnibus_version'

class OmnibusRelease < Release
  class VersionFileDoesnNotExistError < StandardError; end

  private

  def version_class
    OmnibusVersion
  end

  def bump_versions
    version_files.each do |file|
      bump_version(file, version_from_gitlab_repo(file))
    end
  end

  def version_files
   files = %w[VERSION GITLAB_SHELL_VERSION GITLAB_WORKHORSE_VERSION]
   files << 'GITLAB_PAGES_VERSION' if version.ee?
   files
  end

  def version_from_gitlab_repo(file_name)
    file_path = File.join(repository.path, file_name)
    unless File.exist?(file_path)
      raise VersionFileDoesnNotExistError.new(file_path)
    end

    read_file_from_gitlab_repo(file_name)
  end

  def read_file_from_gitlab_repo(file_name)
    gitlab_file_path = File.join(options[:gitlab_repo_path], file_name)
    unless File.exist?(gitlab_file_path)
      raise VersionFileDoesnNotExistError.new(gitlab_file_path)
    end

    File.read(gitlab_file_path).strip
  end

end
