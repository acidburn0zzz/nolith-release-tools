# frozen_string_literal: true

module ReleaseTools
  class GemfileParser
    include ::SemanticLogger::Loggable

    LockfileNotFoundError = Class.new(StandardError) do
      def initialize(file_name)
        super("Unable to find file #{file_name}")
      end
    end

    VersionNotFoundError = Class.new(StandardError) do
      def initialize(gem_name)
        super("Unable to find a version for gem #{gem_name}")
      end
    end

    def initialize(lockfile)
      @lockfile = lockfile

      raise LockfileNotFoundError, lockfile unless File.exist?(lockfile)

      @parsed_file = Bundler::LockfileParser.new(Bundler.read_file(lockfile))
    end

    def gem_version(gem_name)
      spec = @parsed_file.specs.find { |x| x.name == gem_name }

      raise VersionNotFoundError, gem_name if spec.nil?

      version = spec.version.to_s

      logger.trace('Version from gemfile', gem: gem_name, version: version)

      version
    end
  end
end
