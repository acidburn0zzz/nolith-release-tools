module Packages
  class PublishService
    PipelineNotFoundError = Class.new(StandardError)

    attr_reader :version, :project

    # Jobs in these stages will be "played"
    PLAY_STAGES = %w[
      package-release
      image-release
      raspian_release
    ]

    def initialize(version)
      @version = version
      @project = Project::OmnibusGitlab
    end

    def execute
    end

    private

    def project_path
      project.dev_path
    end

    def client
      GitlabDevClient
    end
  end
end
