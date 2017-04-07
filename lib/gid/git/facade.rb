require_relative '../../repository'

module Gid
  module Git
    class Facade
      def initialize(path, stable_branch)
        @path = path
        @stable_branch = stable_branch
      end

      def pull
        run_multiple(
          [%w(stash),
           %w(checkout master),
           %w(pull origin master),
           %w(checkout) + [@stable_branch],
           %w(pull origin) + [@stable_branch]])
      end

      def cherry_pick(sha)
        unless run_git %W(cherry-pick -m 1 #{sha})
          raise StandardError.new('Cannot cherry pick :( Please resolve the conflict manually and start again.')
        end
      end

      def push
        # TODO
        # Done manually, so we don't screw stuff in the remote
        # repository.push_to_all_remotes(branch)
      end

      private

      def run_multiple(args)
        args.each do |arg|
          raise StandardError.new("Cannot run: #{arg}") unless run_git(arg)
        end
      end

      def run_git(args)
        Dir.chdir(@path) do
          # TODO pass proper args
          args.unshift('git')

          Output::Logger.write("$ #{args.join(' ')}")

          Open3.popen3(args.join(' ')) do |_in, stdout, stderr, exit|
            Output::Logger.write(stdout.read)
            Output::Logger.write(stderr.read)

            return exit.value.success?
          end
        end
      end
    end
  end
end
