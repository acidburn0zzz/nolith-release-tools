class TeamMember
  attr_accessor :name, :username

  def initialize(name:, username:)
    @name = name
    @username = username
  end

  def ==(other)
    name == other.name && username == other.username
  end
end
