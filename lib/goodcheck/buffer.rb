module Goodcheck
  class Buffer
    attr_reader :path
    attr_reader :content

    def initialize(path:, content:)
      @path = path
      @content = content
    end

    def line_starts
      unless @line_starts
        @line_starts = []

        start_position = 0

        content.lines.each do |line|
          range = start_position..(start_position + line.bytesize)
          @line_starts << range
          start_position = range.end
        end
      end

      @line_starts
    end

    def location_for_position(position)
      line_index = line_starts.bsearch_index do |range|
        position < range.end
      end

      if line_index
        [line_index + 1, position - line_starts[line_index].begin]
      end
    end

    def line(line_number)
      content.lines[line_number - 1]
    end

    def position_for_location(line, column)
      if (range = line_starts[line - 1])
        pos = range.begin + column
        if pos < range.end
          pos
        end
      end
    end
  end
end
