require_relative '../gitlab_client'
require_relative '../gitlab_dev_client'

module Qa
  class ProjectChangeset
    attr_reader :project, :from, :to, :default_client

    def initialize(project:, from:, to:, default_client: GitlabClient)
      @project = project
      @from = from
      @to = to
      @default_client = default_client

      verify_refs!(from, to)
    end

    def merge_requests
      @merge_requests ||= gather_merge_requests
    end

    def commits
      @commits ||= default_client.compare(project, from: from, to: to).commits
    end

    def shas
      commits.map { |commit| commit['id'] }
    end

    private

    def alternate_client
      default_client == GitlabDevClient ? GitlabClient : GitlabDevClient
    end

    def gather_merge_requests
      commits.each_with_object([]) do |commit, mrs|
        if mr = extract_mr_data(commit)
          mrs << retrieve_merge_request(mr[:path], mr[:iid])
        end
      end
    end

    def retrieve_merge_request(path, iid)
      default_client.merge_request(OpenStruct.new(path: path, dev_path: path), iid: iid)
    rescue Gitlab::Error::NotFound
      alternate_client.merge_request(OpenStruct.new(path: path, dev_path: path), iid: iid)
    end

    def extract_mr_data(commit)
      matcher = commit['message'].match(/See merge request (?<path>\S*)!(?<iid>\d+)/)
      if matcher
        {
          path: matcher[:path],
          iid: matcher[:iid]
        }
      end
    end

    def verify_refs!(*refs)
      refs.each do |ref|
        begin
          default_client.commit(project, ref: ref)
        rescue Gitlab::Error::NotFound
          raise ArgumentError.new("Invalid ref for this repository: #{ref}")
        end
      end
    end
  end
end
