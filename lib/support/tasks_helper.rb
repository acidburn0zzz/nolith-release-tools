def get_version(args)
  version = Version.new(args[:version])

  unless version.valid?
    $stdout.puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def dry_run?
  ENV['TEST'].present?
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

def no_mention?
  ENV['NO_MENTION'].present?
end

def create_or_show_issuable(issuable, type)
  if issuable.exists?
    $stdout.puts "--> #{type} \"#{issuable.title}\" already exists.".red
    $stdout.puts "    #{issuable.url}"
    exit 1
  else
    issuable.create
    raise "No #{type} was created!" unless issuable.exists?
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
