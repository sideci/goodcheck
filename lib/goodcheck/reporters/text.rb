module Goodcheck
  module Reporters
    class Text
      attr_reader :stdout

      def initialize(stdout:)
        @stdout = stdout
        @file_count = 0
        @issue_count = 0
      end

      def analysis
        yield
      end

      def file(path)
        @file_count += 1
        yield
      end

      def rule(rule)
        yield
      end

      def issue(issue)
        @issue_count += 1

        message = issue.rule.message.lines.first.chomp

        if issue.location
          start_line = issue.location.start_line
          start_column = issue.location.start_column
          start_column_index = start_column - 1
          line = issue.buffer.line(start_line)
          column_size = if issue.location.one_line?
                          issue.location.column_size
                        else
                          line.bytesize - start_column
                        end
          rule = Rainbow("(#{issue.rule.id})").darkgray
          severity = issue.rule.severity ? Rainbow("[#{issue.rule.severity}]").magenta : ""
          stdout.puts "#{Rainbow(issue.path).cyan}:#{start_line}:#{start_column}: #{message}  #{rule}  #{severity}".strip
          stdout.puts line.chomp
          stdout.puts (" " * start_column_index) + Rainbow("^" + "~" * (column_size - 1)).yellow
        else
          stdout.puts "#{Rainbow(issue.path).cyan}:-:-: #{message}"
        end
      end

      def summary
        files = case @file_count
                when 0
                  "no files"
                when 1
                  "1 file"
                else
                  "#{@file_count} files"
                end
        issues = case @issue_count
                 when 0
                   Rainbow("no issues").green
                 when 1
                   Rainbow("1 issue").red
                 else
                   Rainbow("#{@issue_count} issues").red
                 end

        stdout.puts ""
        stdout.puts "#{files} inspected, #{issues} detected"
      end
    end
  end
end
