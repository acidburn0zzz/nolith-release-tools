module Gid
  module Tasks
    class StableMr
      attr_reader :id, :merge_commit_sha, :web_url, :iid, :title

      def initialize(mr, version)
        @id = mr.id
        @merge_commit_sha = mr.merge_commit_sha
        @web_url = mr.web_url
        @iid = mr.iid
        @title = mr.title
        @project_id = mr.project_id
        @version = version
      end

      def to_s
        "IID: #{iid} Title: #{title}"
      end

      def to_log
        Output::Logger.write(to_s)
      end

      def leave_note!
        Gitlab.create_merge_request_note(@project_id, mr.id, mr_note)
      end

      def mr_note
        'Picked into stable. Will be in `' + @version + '`.' + "\n" + '/unlabel ~"Pick into Stable"'
      end
    end
  end
end
