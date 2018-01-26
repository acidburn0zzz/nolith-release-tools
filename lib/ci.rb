class CI
  def self.current_job_url
    return unless ENV['CI_JOB_ID']

    "https://gitlab.com/gitlab-org/release-tools/-/jobs/#{ENV['CI_JOB_ID']}"
  end
end
