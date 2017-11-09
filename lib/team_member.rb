class TeamMember
  attr_accessor :name, :username

  def initialize(name:, username:)
    @name = name
    @username = username
  end
end
