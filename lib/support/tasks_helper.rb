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
  SharedStatus.security_release?
end

def no_mention?
  ENV['NO_MENTION'].present?
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
