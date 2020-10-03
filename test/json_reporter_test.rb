require "test_helper"

class JSONReporterTest < Minitest::Test
  Reporters = Goodcheck::Reporters
  Rule = Goodcheck::Rule
  Issue = Goodcheck::Issue
  Buffer = Goodcheck::Buffer

  include Outputs

  def test_reporter
    reporter = Reporters::JSON.new(stdout: stdout, stderr: stderr)

    json_analysis = reporter.analysis do
      reporter.file Pathname("foo.txt") do
        rule = Rule.new(id: "id", triggers: [], message: "Message", justifications: ["reason1", "reason2"])
        reporter.rule rule do
          buffer = Buffer.new(path: Pathname("foo.txt"), content: "a\nb\nc\nd\ne")
          issue = Issue.new(buffer: buffer, range: 0...2, rule: rule, text: "a ")
          reporter.issue(issue)
        end
      end
    end

    json = JSON.parse(stdout.string, symbolize_names: true)

    assert_equal [{ rule_id: "id",
                    path: "foo.txt",
                    location: {
                      start_line: 1,
                      start_column: 0,
                      end_line: 2,
                      end_column: 0,
                    },
                    message: "Message",
                    justifications: ["reason1", "reason2"]
                  }], json
    assert_equal json, JSON.parse(JSON.dump(json_analysis), symbolize_names: true)
  end
end
