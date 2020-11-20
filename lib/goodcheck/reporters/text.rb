module Goodcheck
  module Reporters
    class Text
      attr_reader :stdout

      def initialize(stdout:)
        @stdout = stdout
      end

      def analysis
        yield
      end

      def file(path)
        yield
      end

      def rule(rule)
        yield
      end

      def issue(issue)
        if issue.location
          start_line = issue.location.start_line
          start_column_index = issue.location.start_column - 1
          line = issue.buffer.line(start_line)
          column_size = if issue.location.one_line?
                         issue.location.column_size
                       else
                         line.bytesize
                       end
          colored_line = line.byteslice(0, start_column_index) +
                         Rainbow(line.byteslice(start_column_index, column_size)).red +
                         line.byteslice((start_column_index + column_size)..)
          stdout.puts "#{issue.path}:#{start_line}:#{colored_line.chomp}:\t#{issue.rule.message.lines.first.chomp}"
        else
          line = issue.buffer.line(1)&.chomp
          line = line ? Rainbow(line).red : '-'
          stdout.puts "#{issue.path}:-:#{line}:\t#{issue.rule.message.lines.first.chomp}"
        end
      end
    end
  end
end
