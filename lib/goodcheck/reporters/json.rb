module Goodcheck
  module Reporters
    class JSON
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :issues

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
        @issues = []
      end

      def analysis
        yield

        json = issues.map do |issue|
          location = issue.location
          {
            rule_id: issue.rule.id,
            path: issue.path,
            location: location && {
              start_line: location.start_line,
              start_column: location.start_column,
              end_line: location.end_line,
              end_column: location.end_column
            },
            message: issue.rule.message,
            justifications: issue.rule.justifications,
            severity: issue.rule.severity
          }
        end
        stdout.puts ::JSON.dump(json)
        json
      end

      def file(path)
        yield
      end

      def rule(rule)
        yield
      end

      def issue(issue)
        issues << issue
      end

      def summary
        # noop
      end
    end
  end
end
