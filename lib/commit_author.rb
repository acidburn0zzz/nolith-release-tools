class CommitAuthor
  TEAM_DATA_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/raw/master/data/team.yml'.freeze
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
  CORE_TEAM_MAPPING = {
    'blackst0ne' => 'blackst0ne'
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

    @gitlab_username ||= names_to_gitlab_usernames[canonical_name]
  end

  def canonical_name
    @canonical_name ||=
      GIT_NAMES_TO_TEAM_PAGE_NAMES.fetch(git_name) do
        (
          names_to_gitlab_usernames.find { |name, _| name.start_with?(git_name) }&.first ||
          git_name
        ).tr('"', "'")
      end
  end

  # Return a hash like: { "John Doe" => "john_doe_gitlab_username" }
  def names_to_gitlab_usernames
    @names_to_gitlab_usernames ||= begin
      response = HTTParty.get(TEAM_DATA_URL)

      YAML.safe_load(response.body).map do |member|
        [member['name'], member['gitlab']]
      end.to_h.merge(CORE_TEAM_MAPPING)
    end
  end
end
