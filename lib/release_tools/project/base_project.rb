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

      def self.remotes
        if SharedStatus.security_release?
          self::REMOTES.slice(:dev)
        else
          self::REMOTES
        end
      end

      def self.path
        extract_path_from_remote(:canonical).captures.join('/')
      end

      def self.dev_path
        extract_path_from_remote(:dev).captures.join('/')
      end

      def self.group
        extract_path_from_remote(:canonical)[:group]
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
        remote = self::REMOTES.fetch(remote_key) do |name|
          raise "Invalid remote for #{self}: #{name}"
        end

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
