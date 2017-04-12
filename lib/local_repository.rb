require 'open3'

class LocalRepository
  def self.ready?
    new.ready?
  end

  def ready?
    master_branch? && up_to_date?
  end

  private

  def master_branch?
    run_git('rev-parse --abbrev-ref HEAD').chomp == 'master'
  end

  def up_to_date?
    !run_git('pull --ff-only').nil?
  end

  def run_git(command)
    out, err, st = Open3.capture3('git ' + command)

    raise ScriptError.new(err) unless st.success?

    out
  end
end
