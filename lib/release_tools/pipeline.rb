module ReleaseTools
  class Pipeline
    attr_reader :project, :sha

    def initialize(project, sha, versions)
      @project = project
      @sha = sha
      @token = ENV.fetch('OMNIBUS_BUILD_TRIGGER_TOKEN') do |name|
        raise "Missing environment variable `#{name}`"
      end
      @versions = versions
    end

    def trigger
      $stdout.puts "Trigger build: #{sha} for #{project.path}".indent(4)

      trigger = ReleaseTools::GitlabDevClient.run_trigger(
        ReleaseTools::Project::OmnibusGitlab,
        @token,
        'master',
        build_variables
      )

      $stdout.puts "Pipeline triggered: #{trigger.web_url}".indent(4)

      wait(trigger.id)
    end

    private

    def status(id)
      ReleaseTools::GitlabDevClient.pipeline(ReleaseTools::Project::OmnibusGitlab, id).status
    end

    def wait(id)
      interval = 60 # seconds
      max_duration = 3600 * 3 # 3 hours
      start = Time.now.to_i

      $stdout.puts "Waiting on pipeline for #{max_duration} seconds...".indent(4)

      loop do
        if ReleaseTools::TimeUtil.timeout?(start, max_duration)
          raise "Pipeline timeout after waiting for #{max_duration} seconds."
        end

        case status(id)
        when 'created', 'pending', 'running'
          sleep interval
        when 'success'
          $stdout.puts "Pipeline succeeded in #{max_duration} seconds."
          break
        else
          raise 'Pipeline did not succeed.'
        end
      end
    end

    def build_variables
      @versions.merge(
        'GITLAB_VERSION' => @sha,
        'NIGHTLY' => 'true',
        'ee' => @project == ReleaseTools::Project::GitlabEe
      )
    end
  end
end
