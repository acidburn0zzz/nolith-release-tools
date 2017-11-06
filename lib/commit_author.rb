require_relative 'team'

class CommitAuthor
  attr_reader :team, :git_name, :git_names_to_team_names

  def initialize(git_name, team: Team.new, git_names_to_team_names: default_git_names_to_team_names)
    @team = team
    @git_name = git_name
    @git_names_to_team_names = git_names_to_team_names
  end

  def to_gitlab(reference: false)
    if gitlab_username
      reference ? "@#{gitlab_username}" : gitlab_username
    else
      git_name
    end
  end

  private

  def default_git_names_to_team_names
    YAML.load_file(File.expand_path('../git_names_to_team_names.yml', __dir__))
  end

  def gitlab_username
    @gitlab_username ||= team.find_by_name(canonical_name)&.username
  end

  def canonical_name
    @canonical_name ||= git_names_to_team_names.fetch(git_name, git_name)
  end
end
