module Goodcheck
  # In the example below, each attribute is:
  #
  # - start_line: 2
  # - start_column: 3
  # - end_line: 2
  # - end_column: 9
  #
  # @example
  #
  #   1 |
  #   2 | A matched text
  #   3 |   ^~~~~~~
  #         3456789
  #
  class Location
    attr_reader :start_line
    attr_reader :start_column
    attr_reader :end_line
    attr_reader :end_column

    def initialize(start_line:, start_column:, end_line:, end_column:)
      @start_line = start_line
      @start_column = start_column
      @end_line = end_line
      @end_column = end_column
    end

    def one_line?
      start_line == end_line
    end

    def column_size
      end_column - start_column + 1
    end

    def ==(other)
      other.is_a?(Location) &&
        other.start_line == start_line &&
        other.start_column == start_column &&
        other.end_line == end_line &&
        other.end_column == end_column
    end

    alias eql? ==

    def hash
      self.class.hash ^ start_line.hash ^ start_column.hash ^ end_line.hash ^ end_column.hash
    end
  end
end
