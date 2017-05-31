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

def create_or_show_issuable(issuable, type)
  if issuable.exists?
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

# Prompt the user to input something
#
# message - the message to display before input
# choices - array of strings of acceptable answers or nil for any answer
#
# Returns the user's answer
def prompt(message, choices = nil)
  begin
    print(message)
    answer = STDIN.gets.chomp
  end while choices.present? && !choices.include?(answer)
  answer
end
