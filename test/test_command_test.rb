require "test_helper"

class TestCommandTest < Minitest::Test
  Test = Goodcheck::Commands::Test

  include Outputs

  def with_config(content)
    TestCaseBuilder.tmpdir do |builder|
      builder.config(content: content)
      yield builder
    end
  end

  def test_no_rules
    with_config("rules: []") do |builder|
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 0, result

      assert_equal <<MSG, stdout.string
No rules.
MSG
    end
  end

  def test_ok_pattern
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Hello
  - id: sample.2
    pattern:
      - token: "[NSArray new]"
    message: Bar
    pass:
      - "[[NSArray alloc] init]"
    fail:
      - "[NSArray new]"
      - "[NSArray  new ]"
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 0, result

      assert_equal <<MSG, stdout.string
Validating rule id uniqueness...
  OK!👍
Testing rule sample.2...
  Testing pattern...
  OK!🎉

Tested 1 rule, 1 success, 0 failures
MSG
    end
  end

  def test_ok_trigger
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Hello
  - id: sample.2
    trigger:
      - pattern:
          - token: "[NSArray new]"
        glob: []
        pass:
          - "[[NSArray alloc] init]"
        fail:
          - "[NSArray new]"
          - "[NSArray  new ]"
      - pattern:
          - token: "dangerouslySetInnerHTML={"
        glob: []
        fail:
          - "<div dangerouslySetInnerHTML={value} />"
    message: Bar
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 0, result
      assert_equal <<MSG, stdout.string
Validating rule id uniqueness...
  OK!👍
Testing rule sample.2...
  Testing 1st trigger...
  Testing 2nd trigger...
  OK!🎉

Tested 1 rule, 1 success, 0 failures
MSG
    end
  end

  def test_id_duplicate
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Hello
  - id: sample.1
    pattern: bar
    message: Bar
  - id: sample.2
    pattern: baz
    message: Baz
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 1, result

      assert_equal <<MSG, stdout.string
Validating rule id uniqueness...
  Found 1 duplication.😞
    sample.1
MSG
    end
  end

  def test_trigger_fail
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    message: Hello
    trigger:
      - pattern:
          - foo
        glob: []
        pass: foobar
        fail:
          - foo bar
          - baz
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 1, result
      assert_equal <<MSG, stdout.string
Validating rule id uniqueness...
  OK!👍
Testing rule sample.1...
  Testing 1st trigger...
    1st pass example matched.😱
    2nd fail example didn't match.😱

Failed rules:
  - sample.1

Tested 1 rule, 0 successes, 1 failure
MSG
    end
  end

  def test_pattern_skip
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    message: Hello
    pattern:
      literal: foo
      glob: ["foo.rb"]
    pass: foobar
    fail:
      - baz
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 1, result
      assert_equal <<MSG, stdout.string
Validating rule id uniqueness...
  OK!👍
Testing rule sample.1...
  Testing pattern...
    1st pass example matched.😱
  Testing pattern...
    1st pass example matched.😱
  🚨 The rule contains a `pattern` with `glob`, which is not supported by the test command.
    Skips testing `fail` examples.

Failed rules:
  - sample.1

Tested 1 rule, 0 successes, 1 failure
MSG
    end
  end
end
