module Goodcheck
  class Issue
    attr_reader :buffer
    attr_reader :range
    attr_reader :rule
    attr_reader :text

    def initialize(buffer:, range:, rule:, text:)
      @buffer = buffer
      @range = range
      @rule = rule
      @text = text
      @location = nil
    end

    def path
      buffer.path
    end

    def location
      if range
        unless @location
          start_line, start_column = buffer.location_for_position(range.begin)
          end_line, end_column = buffer.location_for_position(range.end)
          @location = Location.new(start_line: start_line, start_column: start_column, end_line: end_line, end_column: end_column)
        end

        @location
      end
    end

    def ==(other)
      other.is_a?(Issue) &&
        other.buffer == buffer &&
        other.range == range &&
        other.rule == rule
    end

    alias eql? ==

    def hash
      self.class.hash ^ buffer.hash ^ range.hash ^ rule.hash
    end
  end
end
