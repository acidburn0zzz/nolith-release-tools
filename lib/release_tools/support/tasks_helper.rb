# frozen_string_literal: true

def get_version(args)
  version = ReleaseTools::Version.new(args[:version])

  unless version.valid?
    $stdout.puts "Version number must be in the following format: X.Y.Z-rc1 or X.Y.Z".colorize(:red)
    exit 1
  end

  version
end

def dry_run?
  ReleaseTools::SharedStatus.dry_run?
end

def force?
  ENV['FORCE'].present?
end

def skip?(repo)
  ENV[repo.upcase] == 'false'
end

def no_mention?
  ENV['NO_MENTION'].present?
end

def create_or_show_issuable(issuable)
  if dry_run?
    $stdout.puts
    $stdout.puts "# #{issuable.title}"
    $stdout.puts
    $stdout.puts issuable.description
  elsif issuable.exists?
    issuable.status = :exists

    $stdout.puts "--> #{issuable.type} \"#{issuable.title}\" already exists.".red
    $stdout.puts "    #{issuable.url}"

    ReleaseTools::Slack::ChatopsNotification.release_issue(issuable)
  elsif issuable.create?
    issuable.create
    issuable.status = :created
    issuable.link!

    $stdout.puts "--> #{issuable.type} \"#{issuable.title}\" created.".green
    $stdout.puts "    #{issuable.url}"

    ReleaseTools::Slack::ChatopsNotification.release_issue(issuable)
  else
    $stdout.puts 'No QA issue has to be created'
  end
end

def create_or_show_issue(issue)
  create_or_show_issuable(issue)
end

def create_or_show_merge_request(merge_request)
  create_or_show_issuable(merge_request)
end

def cherry_pick_result(result)
  if result.success?
    "✓ #{result.url}"
  else
    "✗ #{result.url}"
  end
end
