module ReleaseTools
  class Pipeline
    attr_reader :project, :sha

    def initialize(project, sha)
      @project = project
      @sha = sha
      @token = ENV.fetch('OMNIBUS_BUILD_TRIGGER_TOKEN') { |name| raise "Missing environment variable `#{name}`" }
    end

    def trigger
      $stdout.puts "trigger build: #{sha} for #{project.path}"
      trigger = ReleaseTools::GitlabDevClient.run_trigger(
        ReleaseTools::Project::OmnibusGitlab,
        @token,
        "master",
        GITLAB_VERSION: sha,
        NIGHTLY: "true",
        ee: project == ReleaseTools::Project::GitlabEe
      )
      $stdout.puts "Pipeline triggered: #{trigger.web_url}"
      wait(trigger.id)
    end

    def status(id)
      ReleaseTools::GitlabDevClient.pipeline(ReleaseTools::Project::OmnibusGitlab, id).status
    end

    def wait(id)
      interval = 60 # seconds
      max_duration = 3600 * 3 # 3 hours
      start = Time.now.to_i
      loop do
        if ReleaseTools::TimeUtil.timeout?(start, max_duration)
          raise "Pipeline timeout after waiting for #{max_duration} seconds."
        end

        case status(id)
        when 'created', 'pending', 'running'
          print '.'
          sleep interval
        when 'success'
          $stdout.puts "Pipeline succeeded in #{max_duration} seconds."
          break
        else
          raise 'Pipeline did not suceed.'
        end

        $stdout.flush
      end
    end
  end
end
