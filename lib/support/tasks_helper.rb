def get_version(args)
  version = Version.new(args[:version])

  unless version.valid?
    $stdout.puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def dry_run?
  SharedStatus.dry_run?
end

def force?
  ENV['FORCE'].present?
end

def skip?(repo)
  ENV[repo.upcase] == 'false'
end

def security_release?
  ENV['SECURITY'] == 'true'
end

def create_or_show_issuable(issuable, type)
  if dry_run?
    $stdout.puts
    $stdout.puts "# #{issuable.title}"
    $stdout.puts
    $stdout.puts issuable.description
  elsif issuable.exists?
    $stdout.puts "--> #{type} \"#{issuable.title}\" already exists.".red
    $stdout.puts "    #{issuable.url}"
    exit 1
  else
    issuable.create
    $stdout.puts "--> #{type} \"#{issuable.title}\" created.".green
    $stdout.puts "    #{issuable.url}"
  end
end

def create_or_show_issue(issue)
  create_or_show_issuable(issue, "Issue")
end

def create_or_show_merge_request(merge_request)
  create_or_show_issuable(merge_request, "Merge Request")
end

def moved_to_bin_message(task_name)
  $stdout.puts "This task has moved to " << "bin/#{task_name}".colorize(:red)
  $stdout.puts "Run it with #{"--help".colorize(:red)} for details and usage."
end
