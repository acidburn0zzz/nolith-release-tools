module Changelog
  class Config
    def self.log(ee: false)
      ee ? ee_log : ce_log
    end

    def self.ce_log
      'CHANGELOG.md'
    end

    def self.ee_log
      'CHANGELOG-EE.md'
    end

    def self.path(ee: false)
      ee ? ee_path : ce_path
    end

    # Relative path to unreleased CE changelog entries
    def self.ce_path
      File.join(root_path, 'unreleased')
    end

    # Relative path to unreleased EE changelog entries
    def self.ee_path
      "#{ce_path}-ee"
    end

    def self.extension
      '.yml'
    end

    def self.root_path
      'changelogs'
    end
  end
end
