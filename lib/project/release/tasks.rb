module Project
  module Release
    class Tasks < ::Project::BaseProject
      def self.group
        "#{super}/release"
      end

      def self.path
        "#{group}/tasks"
      end
    end
  end
end
