# frozen_string_literal: true

module ReleaseTools
  module Project
    class BaseProject
      REMOTE_PATTERN = %r{
        \A.*:
        (?<group>.*)
        \/
        (?<project>[^\/]+)
        \.git\z
      }x.freeze

      # The default remote should be set to the source of repository mirroring
      DEFAULT_REMOTE = :canonical

      def self.remotes
        if SharedStatus.security_release?
          self::REMOTES.slice(:dev)
        else
          self::REMOTES
        end
      end

      def self.path
        extract_path_from_remote(self::DEFAULT_REMOTE).captures.join('/')
      end

      def self.dev_path
        extract_path_from_remote(:dev).captures.join('/')
      end

      def self.group
        extract_path_from_remote(self::DEFAULT_REMOTE)[:group]
      end

      def self.dev_group
        extract_path_from_remote(:dev)[:group]
      end

      def self.to_s
        if SharedStatus.security_release?
          dev_path
        else
          path
        end
      end

      def self.inspect
        to_s
      end

      def self.extract_path_from_remote(remote_key)
        raise "Invalid remote: #{remote_key}" unless self::REMOTES.key?(remote_key)

        remote = self::REMOTES[remote_key]

        if remote =~ REMOTE_PATTERN
          $LAST_MATCH_INFO
        else
          raise "Unable to extract path from #{remote}"
        end
      end

      private_class_method :extract_path_from_remote
    end
  end
end
