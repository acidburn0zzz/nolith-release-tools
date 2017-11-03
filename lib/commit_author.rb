class CommitAuthor
  # Mappings from actual Git committer names to team page's names.
  # https://about.gitlab.com/team/
  GIT_NAMES_TO_TEAM_PAGE_NAMES = {
    'Luke "Jared" Bennett' => "Luke 'Jared' Bennett",
    'Achilleas Pipinellis' => "Achilleas 'Axil' Pipinellis",
    'Kamil Trzcinski' => 'Kamil Trzciński',
    'Ruben Davila' => 'Rubén Dávila',
    'Nick Thomas' => "Nicholas 'Nick' Thomas",
    'Lin Jen-Shin' => 'Jen-Shin Lin',
    'Douglas Barbosa Alexandre' => 'Douglas Alexandre',
    'Jarka Kadlecova' => "Jaroslava 'Jarka' Kadlecová",
    'Balasankar C' => 'Balasankar "Balu" C',
    'winniehell' => 'Winnie Hellmann',
    'kushalpandya' => 'Kushal Pandya'
  }.freeze

  attr_reader :git_name

  def initialize(git_name)
    @git_name = git_name
  end

  def to_gitlab(reference: false)
    if gitlab_username
      reference ? "@#{gitlab_username}" : gitlab_username
    else
      git_name
    end
  end

  private

  def gitlab_username
    return @gitlab_username if defined?(@gitlab_username)

    @gitlab_username ||= gitlab_team.find_by_name(canonical_name)&.username
  end

  def canonical_name
    @canonical_name ||= GIT_NAMES_TO_TEAM_PAGE_NAMES.fetch(git_name, git_name)
  end

  def gitlab_team
    @gitlab_team ||= Team.new
  end
end
