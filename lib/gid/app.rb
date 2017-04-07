#  cd /Users/James/Development/release-tools && irb
# load './lib/release/gid/app.rb'
# Gid::App.run
require 'curses'
require 'dispel'
require 'open3'
require_relative 'config'
require_relative '../version'
require 'colorize'

module Gid
  class App
    def self.run(*args)
      new(*args).run
    end

    def initialize(version)
      # TODO pass as arguments
      @version = Version.new(version)
      @selected = 0

      Output::Logger.archive!
    end

    def run
      puts 'GitLab Interactive Deploy (Alpha)'.colorize(:cyan)
      puts 'WARNING: Experimental - Use at your own risk'.colorize(:red)
      sleep 2

      Dispel::Screen.open(colors: Config.colors) do |screen|
        map = lambda do
          Gid::Styles.new(screen, help_bar.default_message_length, @selected).get
        end

        # proc does not complain about arity
        redraw = proc do |status|
          screen.draw(output(screen, status || check_status), map.call, [-1, 0])
        end

        wait_for_keyboard(redraw)
      end
    end

    def wait_for_keyboard(redraw)
      Dispel::Keyboard.output timeout: 1 do |key|
        case key
          when :timeout
            redraw.call
          when :'Ctrl+x'
            break
          when :up
            move_up

            redraw.call
          when :down
            move_down

            redraw.call
          when :enter
            task_list[@selected].run!
          else
            redraw.call(key) unless %w(r e f).include?(key)
        end
      end
    end

    private

    def output(screen, status)
      [info_bar, task_list, output_log.to_s(screen.lines.to_i), help_bar.to_s(status)].join("\n" * 2)
    end

    def info_bar
      @info_bar ||= Output::InfoBar.new(@version)
    end

    def help_bar
      @help_bar ||= Output::HelpBar.new
    end

    def output_log
      @output_log ||= Output::Log.new
    end

    def task_list
      @task_list ||= Output::TaskList.new(@version)
    end

    def check_status
      task_list.running? ? task_list[@selected].status : ''
    end

    def move_up
      @selected -=1 unless @selected.zero?
    end

    def move_down
      @selected +=1 unless @selected >= task_list.size - 1
    end
  end
end

Gid::App.run(ARGV[0])
