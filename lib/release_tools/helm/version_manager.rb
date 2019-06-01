# frozen_string_literal: true

module ReleaseTools
  module Helm
    class VersionManager
      attr_reader :repository, :version

      def initialize(repository)
        case repository
        when RemoteRepository
          @repository = repository
        else
          raise "Invalid repository: #{repository}"
        end
      end

      def get_latest_version(versions)
        max_version = VersionSorter.sort(versions).last # rubocop:disable Performance/UnneededSort
        HelmGitlabVersion.new(max_version.sub('v', ''))
      end

      def get_matching_tags(messages, major: '\d+', minor: '\d+', patch: '\d+')
        messages.select { |_tag, message| message.match?(/contains GitLab (?:CE|EE) #{major}\.#{minor}\.#{patch}/) }
      end

      # Determine the next helm chart using existing tags in the repo. The
      # logic is as follows
      # 0. Check if a tag already exist matching the pattern <MAJOR>.<MINOR>.<PATCH>
      #    If so, a chart version already exists for the specified GitLab version.
      #    We return it, and let the tag creation code to detect it and skip
      #    the tag push
      # 1. Else, check if tags already exist matching the pattern <MAJOR>.<MINOR>.#.
      #    If so, we are releasing a new patch version
      # 2. Else, check if tags already exist matching the pattern <MAJOR>.#.#.
      #    If so, we are releasing a new minor version
      # 3. Else, we are releasing a new major version
      def next_version(gitlab_version)
        tag_messages = repository.tag_messages

        raise "Tag messages could not be extracted from the repository to compute next tag. Aborting." unless tag_messages

        matching_patch_tags = get_matching_tags(tag_messages, major: gitlab_version.major, minor: gitlab_version.minor, patch: gitlab_version.patch)
        unless matching_patch_tags.empty?
          warn "A chart version already exists for GitLab version #{gitlab_version}"
          return HelmChartVersion.new(matching_patch_tags.keys.first.sub('v', ''))
        end

        matching_minor_tags = get_matching_tags(tag_messages, major: gitlab_version.major, minor: gitlab_version.minor)
        matching_major_tags = get_matching_tags(tag_messages, major: gitlab_version.major)

        next_version = if !matching_minor_tags.empty?
                         # There is a minor version series which matches the
                         # incoming one, and we need to create a new patch
                         # version in that series.
                         get_latest_version(matching_minor_tags.keys).next_patch
                       elsif !matching_major_tags.empty?
                         # There is a major version series which matches the
                         # incoming one, and we need to create a new minor
                         # version in that series.
                         get_latest_version(matching_major_tags.keys).next_minor
                       else
                         # We are on a new major version, and we need to find
                         # the latest major version and bump it
                         get_latest_version(tag_messages.keys).next_major
                       end

        HelmChartVersion.new(next_version)
      end

      def parse_chart_file
        Helm::ChartFile.new(File.join(repository.path, 'Chart.yaml'))
      end
    end
  end
end
