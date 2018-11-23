require_relative "test_helper"

class TestCommandTest < Minitest::Test
  Test = Goodcheck::Commands::Test

  include Outputs

  def with_config(content)
    TestCaseBuilder.tmpdir do |builder|
      builder.config(content: content)
      yield builder
    end
  end

  def test_ok
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

      assert_equal 0, test.run
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

      assert_equal 1, test.run
      assert_match /Found 1 duplications/, stdout.string
      assert_match /sample\.1/, stdout.string
      refute_match /sample\.2/, stdout.string
    end
  end

  def test_pass_matches
    with_config(<<EOF) do |builder|
rules:
  - id: sample.1
    pattern: foo
    message: Hello
    pass: foobar
    fail:
      - foo bar
      - baz
EOF
      test = Test.new(stdout: stdout, stderr: stderr, config_path: builder.config_path, force_download: nil, home_path: builder.path + "home")

      assert_equal 1, test.run
      assert_match /Testing rule sample\.1/, stdout.string
      assert_match /1st pass example matched./, stdout.string
      assert_match /2nd fail example didn't match./, stdout.string
    end
  end
end
