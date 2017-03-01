def get_version(args)
  version = Version.new(args[:version])

  unless version.valid?
    $stdout.puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def skip?(repo)
  ENV[repo.upcase] == 'false'
end

def security_release?
  ENV['SECURITY'] == 'true'
end

def create_or_show_issue(issue)
  if issue.exists?
    $stdout.puts "--> Issue \"#{issue.title}\" already exists.".red
    $stdout.puts "    #{issue.url}"
    exit 1
  else
    issue.create
    $stdout.puts "--> Issue \"#{issue.title}\" created.".green
    $stdout.puts "    #{issue.url}"
  end
end
