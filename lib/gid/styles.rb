module Gid
  class Styles
    def initialize(screen, default_helpbar_length, selected_element)
      @screen = screen
      @default_helpbar_length = default_helpbar_length
      @selected_element = selected_element
    end

    def get
      map = Dispel::StyleMap.new(@screen.lines)

      # Top bar (Info bar) style
      map.add(["#000000", "#d78700"], 0, 0..@screen.columns)

      # Help bar style
      map.add(["#dadada", "#0000d7"], @screen.lines - 1, 0..@default_helpbar_length)
      map.add(["#00ff00", "#0000d7"], @screen.lines - 1, @default_helpbar_length..@screen.columns)

      # Task list style
      map.add(["#00FFFF", "#000000"], 2, 0..@screen.columns)
      map.add(:reverse, 3 + @selected_element, 0..@screen.columns)
      map.add(["#00FFFF", "#000000"], 6, 0..@screen.columns)

      # Log
      7.upto(@screen.lines - 2) do |line|
        map.add(["#5fd787", "#000000"], line, 1..23) # 23 being the timestamp size
      end

      map
    end
  end
end
