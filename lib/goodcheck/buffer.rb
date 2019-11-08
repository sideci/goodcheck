module Goodcheck
  class Buffer
    attr_reader :path
    attr_reader :content

    def initialize(path:, content:)
      @path = path
      @content = content
      @line_ranges = nil
    end

    def line_ranges
      unless @line_ranges
        @line_ranges = []

        start_position = 0

        content.split(/\n/, -1).each do |line|
          range = start_position...(start_position + line.bytesize)
          @line_ranges << range
          start_position = range.end + 1
        end
      end

      @line_ranges
    end

    def location_for_position(position)
      line_index = line_ranges.bsearch_index do |range|
        position <= range.end
      end

      if line_index
        [line_index + 1, position - line_ranges[line_index].begin]
      end
    end

    def line(line_number)
      content.lines[line_number-1]
    end

    def position_for_location(line, column)
      if (range = line_ranges[line-1])
        pos = range.begin + column
        if pos <= range.end
          pos
        end
      end
    end
  end
end
