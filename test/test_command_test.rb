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
Validating rule ID uniqueness...
  OK! 👍
Testing rule sample.1...
  OK! 👍
Testing rule sample.2...
  Testing pattern...
  OK! 👍

2 rules tested: 2 successful, 0 failed
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
Validating rule ID uniqueness...
  OK! 👍
Testing rule sample.1...
  OK! 👍
Testing rule sample.2...
  1. Testing trigger...
  2. Testing trigger...
  OK! 👍

2 rules tested: 2 successful, 0 failed
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

      assert_equal 3, result
      assert_equal <<MSG, stdout.string
Validating rule ID uniqueness...
  Found 1 duplication. 😱
    - sample.1
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

      assert_equal 3, result
      assert_equal <<MSG, stdout.string
Validating rule ID uniqueness...
  OK! 👍
Testing rule sample.1...
  1. Testing trigger...
    1. pass example matched. 😱
    2. fail example didn’t match. 😱

Failed rules:
  - sample.1

1 rule tested: 0 successful, 1 failed
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

      assert_equal 3, result
      assert_equal <<MSG, stdout.string
Validating rule ID uniqueness...
  OK! 👍
Testing rule sample.1...
  Testing pattern...
    1. pass example matched. 😱
  Testing pattern...
    1. pass example matched. 😱
    The rule contains a `pattern` with `glob`, which is not supported by the test command. 🚨
    Skips testing `fail` examples.

Failed rules:
  - sample.1

1 rule tested: 0 successful, 1 failed
MSG
    end
  end

  def test_invalid_config
    with_config(<<EOF) do |builder|
rule:
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 1, result
      assert_empty stdout.string
      assert_match %r(Invalid config:), stderr.string
    end
  end

  def test_no_config
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        test = Test.new(stdout: stdout, stderr: stderr, config_path: Pathname("foo.yml"), force_download: nil, home_path: builder.path + "home")

        assert_equal 1, test.run
        assert_equal "Configuration file not found: foo.yml\n", stderr.string
      end
    end
  end

  def test_invalid_pattern
    with_config(<<EOF) do |builder|
rules:
  - id: foo
    pattern: /[a/
    message: Foo
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 1, result
      assert_empty stdout.string
      assert_match %r(^Invalid pattern of the `foo` rule in `\S+`: premature end of char-class: /\[a/$), stderr.string
    end
  end

  def test_invalid_severity
    with_config(<<EOF) do |builder|
rules:
  - id: foo
    pattern: a
    message: ...
    severity: info
  - id: bar
    pattern: a
    message: ...
severity:
  allow: [error, warn]
  required: true
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")
      result = test.run

      assert_equal 3, result
      assert_equal <<MSG, stdout.string
Validating rule ID uniqueness...
  OK! 👍
Testing rule foo...
  "info" severity isn’t allowed. Must be one of "error", "warn". 😱
Testing rule bar...
  Severity is required. 😱

Failed rules:
  - foo
  - bar

2 rules tested: 0 successful, 2 failed
MSG
    end
  end
end
