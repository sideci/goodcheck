module Goodcheck
  class Buffer
    attr_reader :path
    attr_reader :content

    DISABLE_LINE_PATTERNS = [
      /\/\/ goodcheck-disable-line$/, #JS, Java, C, ...
      /# goodcheck-disable-line$/, # Ruby, Python, PHP, ...
      /-- goodcheck-disable-line$/, # Haskel, SQL, ...
      /<!-- goodcheck-disable-line -->$/, # HTML, Markdown, ...
      /\/\* goodcheck-disable-line \*\/$/, # CSS, SCSS,
      /\{\s*\/\* goodcheck-disable-line \*\/\s*\}$/, # JSX, ...
      /<%# goodcheck-disable-line %>$/, # ERB, ...
      /' goodcheck-disable-line$/, # VB
    ].freeze

    DISABLE_NEXT_LINE_PATTERNS = [
      /\/\/ goodcheck-disable-next-line$/, #JS, Java, C, ...
      /# goodcheck-disable-next-line$/, # Ruby, Python, PHP, ...
      /-- goodcheck-disable-next-line$/, # Haskel, SQL, ...
      /<!-- goodcheck-disable-next-line -->$/, # HTML, Markdown, ...
      /\/\* goodcheck-disable-next-line \*\/$/, # CSS, SCSS,
      /\{\s*\/\* goodcheck-disable-next-line \*\/\s*\}$/, # JSX, ...
      /<%# goodcheck-disable-next-line %>$/, # ERB, ...
      /' goodcheck-disable-next-line$/, # VB
    ].freeze

    class << self
        attr_accessor :DISABLE_LINE_PATTERNS
        attr_accessor :DISABLE_NEXT_LINE_PATTERNS
    end

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
          range = start_position..(start_position + line.bytesize)
          @line_ranges << range
          start_position = range.end + 1
        end
      end

      @line_ranges
    end

    def line_disabled?(line_number)
      if line_number > 1
        return true if DISABLE_NEXT_LINE_PATTERNS.any? { |pattern| line(line_number - 1).match?(pattern) }
      end

      if line_number <= lines.length
        return DISABLE_LINE_PATTERNS.any? { |pattern| line(line_number).match?(pattern) }
      end

      return false
    end

    def location_for_position(position)
      line_index = line_ranges.bsearch_index do |range|
        position <= range.end
      end

      if line_index
        line_number = line_index + 1
        column_number = position - line_ranges[line_index].begin + 1
        [line_number, column_number]
      end
    end

    def lines
      @lines ||= content.lines
    end

    def line(line_number)
      lines[line_number - 1]
    end
  end
end
