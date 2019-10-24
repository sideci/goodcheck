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
          line = issue.buffer.line(issue.location.start_line)
          end_column = if issue.location.start_line == issue.location.end_line
                         issue.location.end_column
                       else
                         line.bytesize
                       end
          colored_line = line.byteslice(0, issue.location.start_column) + Rainbow(line.byteslice(issue.location.start_column, end_column - issue.location.start_column)).red + line.byteslice(end_column, line.bytesize)
          stdout.puts "#{issue.path}:#{issue.location.start_line}:#{colored_line.chomp}:\t#{issue.rule.message.lines.first.chomp}"
        else
          line = issue.buffer.line(1)&.chomp
          line = line ? Rainbow(line).red : '-'
          stdout.puts "#{issue.path}:-:#{line}:\t#{issue.rule.message.lines.first.chomp}"
        end
      end
    end
  end
end
