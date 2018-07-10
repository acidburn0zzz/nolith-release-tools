module Packages
  class PublishService
    class PipelineNotFoundError < StandardError
      def initialize(version)
        super("Pipeline not found for #{version}")
      end
    end

    attr_reader :ce_version, :ee_version, :project

    # Jobs in these stages will be "played"
    # Related: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3663
    PLAY_STAGES = %w[
      package-release
      image-release
      raspbian_release
    ].freeze

    def initialize(version)
      @ce_version = version.to_omnibus(ee: false)
      @ee_version = version.to_omnibus(ee: true)

      @project = Project::OmnibusGitlab
    end

    def execute
      [ee_version, ce_version].each do |version|
        # TODO (rspeicher): Should we warn if there's more than one result for this?
        pipeline = client
          .pipelines(project_path, scope: :tags, ref: version)
          .first

        raise PipelineNotFoundError.new(version) unless pipeline

        triggers = client
          .pipeline_jobs(project_path, pipeline.id, scope: :manual)
          .select { |job| PLAY_STAGES.include?(job.stage) }

        # TODO (rspeicher): How should we handle a case where `triggers` is empty?
        triggers.each do |job|
          client.job_play(project_path, job.id)
        end
      end
    end

    private

    def project_path
      project.dev_path
    end

    def client
      @client ||= GitlabDevClient
    end
  end
end
