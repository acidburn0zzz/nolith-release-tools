require_relative 'base_project'

module Project
  class ReleaseTasks < BaseProject
    def self.path
      "#{group}/release/tasks"
    end
  end
end
