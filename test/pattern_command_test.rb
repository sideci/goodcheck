require "test_helper"

class PatternCommandTest < Minitest::Test
  Pattern = Goodcheck::Commands::Pattern

  include Outputs

  def with_config(content)
    TestCaseBuilder.tmpdir do |builder|
      builder.config(content: content)
      yield builder
    end
  end

  def test_no_rules
    with_config(<<EOF) do |builder|
rules: []
EOF
      pattern = Pattern.new(stdout: stdout, stderr: stderr, path: builder.config_path, ids: [], home_path: builder.path + "home")
      result = pattern.run

      assert_equal 0, result
      assert_equal "", stdout.string
    end
  end

  def test_some_rules
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Foo
  - id: sample.2
    pattern: bar
    message: Bar
EOF
      pattern = Pattern.new(stdout: stdout, stderr: stderr, path: builder.config_path, ids: [], home_path: builder.path + "home")
      result = pattern.run

      assert_equal 0, result
      assert_equal <<OUT, stdout.string
sample.1:
  - /foo/
sample.2:
  - /bar/
OUT
    end
  end

  def test_given_ids
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Foo
  - id: sample.2
    pattern: bar
    message: Bar
EOF
      ids = %w[sample.1]
      pattern = Pattern.new(stdout: stdout, stderr: stderr, path: builder.config_path, ids: ids, home_path: builder.path + "home")
      result = pattern.run

      assert_equal 0, result
      assert_equal <<OUT, stdout.string
sample.1:
  - /foo/
OUT
    end
  end

  def test_given_non_existent_ids
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Foo
  - id: sample.2
    pattern: bar
    message: Bar
EOF
      ids = %w[abc xyz]
      pattern = Pattern.new(stdout: stdout, stderr: stderr, path: builder.config_path, ids: ids, home_path: builder.path + "home")
      result = pattern.run

      assert_equal 0, result
      assert_equal "", stdout.string
    end
  end
end
