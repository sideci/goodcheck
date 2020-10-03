require "test_helper"

class SmokeTest < Minitest::Test
  def goodcheck
    (Pathname(__dir__) + "../exe/goodcheck").to_s
  end

  def shell(*commandline, chdir: Pathname("."))
    Open3.capture3(*(["bundle", "exec"] + commandline), chdir: chdir.to_s)
  end

  def test_nocommand
    TestCaseBuilder.tmpdir do |builder|
      stdout, stderr, status = shell(goodcheck, chdir: builder.path)

      refute_operator status, :success?
      assert_match %r(#{Regexp.escape "Usage: goodcheck <command> [options] [args...]"}), stdout
      assert_equal "", stderr
    end
  end

  def test_invalid_command
    TestCaseBuilder.tmpdir do |builder|
      stdout, stderr, status = shell(goodcheck, "foo", chdir: builder.path)

      refute_operator status, :success?
      assert_match %r(#{Regexp.escape "Usage: goodcheck <command> [options] [args...]"}), stdout
      assert_match %r(invalid command: foo), stderr
    end
  end

  def test_help
    TestCaseBuilder.tmpdir do |builder|
      stdout, _, status = shell(goodcheck, "help", chdir: builder.path)

      assert_operator status, :success?
      assert_match %r(#{Regexp.escape "Usage: goodcheck <command> [options] [args...]"}), stdout
    end
  end

  def test_version
    TestCaseBuilder.tmpdir do |builder|
      stdout, _, status = shell(goodcheck, "version", chdir: builder.path)

      assert_operator status, :success?
      assert_match %r(#{Regexp.escape "goodcheck #{Goodcheck::VERSION}"}), stdout
    end
  end

  def test_version_flag
    TestCaseBuilder.tmpdir do |builder|
      stdout, _, status = shell(goodcheck, "--version", chdir: builder.path)

      assert_operator status, :success?
      assert_match %r(#{Regexp.escape "goodcheck #{Goodcheck::VERSION}"}), stdout
    end
  end

  def test_init
    TestCaseBuilder.tmpdir do |builder|
      _, _, status = shell(goodcheck, "init", chdir: builder.path)
      assert status.success?
      assert_operator builder.config_path, :file?
    end
  end

  def test_init_with_config
    TestCaseBuilder.tmpdir do |builder|
      _, _, status = shell(goodcheck, "init", "--config=hello.yml", chdir: builder.path)
      assert status.success?
      assert_operator builder.path + "hello.yml", :file?
    end
  end

  def test_init_with_force
    TestCaseBuilder.tmpdir do |builder|
      (builder.path + "hello.yml").write("hogehoge")

      _, _, status = shell(goodcheck, "init", "--config=hello.yml", "--force", chdir: builder.path)
      assert status.success?
      assert_operator builder.path + "hello.yml", :file?
    end
  end

  def test_init_and_pass_test
    TestCaseBuilder.tmpdir do |builder|
      _, _, status = shell(goodcheck, "init", chdir: builder.path)
      _, _, status = shell(goodcheck, "test", chdir: builder.path)
      assert status.success?
    end
  end

  def test_test
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: id1
    pattern: hoge
    message: No More Hoge
    pass:
      - Hoge
    fail:
      - hoge hoge
EOF

      _, _, status = shell(goodcheck, "test", chdir: builder.path)

      assert status.success?
    end
  end

  def test_check
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - foo
      - bar
    glob:
      - "app/models/**/*.rb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.file name: Pathname("app/views/welcome/index.html.erb"), content: <<EOF
<h1>Foo Bar Baz</h1>
EOF

      stdout, _, status = shell(goodcheck, "check", ".", chdir: builder.path)

      refute status.success?
      assert_match %r(app/models/user\.rb:2:  belongs_to :foo:\tFoo), stdout
    end
  end

  def test_check_json
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - foo
      - bar
    glob:
      - "app/models/**/*.rb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.file name: Pathname("app/views/welcome/index.html.erb"), content: <<EOF
<h1>Foo Bar Baz</h1>
EOF

      stdout, _, status = shell(goodcheck, "check", "--format=json", ".", chdir: builder.path)

      refute status.success?
      assert_equal [{
                      rule_id: "foo",
                      path: "app/models/user.rb",
                      location: {
                        start_line: 2,
                        start_column: 14,
                        end_line: 2,
                        end_column: 17
                      },
                      message: "Foo",
                      justifications: []
                    }], JSON.parse(stdout, symbolize_names: true)
    end
  end

  def test_check_no_target
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - foo
      - bar
    glob:
      - "app/models/**/*.rb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.file name: Pathname("app/views/welcome/index.html.erb"), content: <<EOF
<h1>Foo Bar Baz</h1>
EOF

      stdout, _, status = shell(goodcheck, "check", chdir: builder.path)

      refute status.success?
      assert_match %r(app/models/user\.rb:2:  belongs_to :foo:\tFoo), stdout
    end
  end

  def test_check_rules
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - foo
    glob:
      - "app/models/**/*.rb"
  - id: bar
    message: Bar
    pattern:
      - regexp: bar
        case_insensitive: true
    glob: "**/*.html.erb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.file name: Pathname("app/views/welcome/index.html.erb"), content: <<EOF
<h1>Foo Bar Baz</h1>
EOF

      stdout, _, status = shell(goodcheck, "check", "-R", "bar", chdir: builder.path)

      refute status.success?
      refute_match %r(app/models/user\.rb), stdout
      assert_match %r(app/views/welcome/index\.html\.erb), stdout
    end
  end

  def test_check_invalid_format
    TestCaseBuilder.tmpdir do |builder|
      stdout, stderr, status = shell(goodcheck, "check", "--format", "foo", chdir: builder.path)

      refute status.success?
      assert_empty stdout
      assert_equal "invalid argument: --format foo\n", stderr
    end
  end

  def test_check_invalid_option
    TestCaseBuilder.tmpdir do |builder|
      stdout, stderr, status = shell(goodcheck, "check", "--foo", chdir: builder.path)

      refute status.success?
      assert_empty stdout
      assert_equal "invalid option: --foo\n", stderr
    end
  end

  def test_check_help
    TestCaseBuilder.tmpdir do |builder|
      stdout, stderr, status = shell(goodcheck, "check", "--help", chdir: builder.path)

      assert status.success?
      assert_equal <<-HELP, stdout
Usage: goodcheck check [options] paths...
    -c, --config=CONFIG              Configuration file path [default: 'goodcheck.yml']
    -v, --verbose                    Set log level to verbose
    -d, --debug                      Set log level to debug
        --force                      Download importing files always
    -R, --rule=RULE                  Only rule(s) to check
        --format=<text|json>         Output format [default: 'text']
        --version                    Print version
    -h, --help                       Show help and quit
      HELP
      assert_empty stderr
    end
  end

  def test_pattern
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: sample.foo
    message: Foo
    pattern:
      - foo
    glob:
      - "app/models/**/*.rb"
  - id: sample.bar
    message: Bar
    pattern:
      - regexp: bar
        case_insensitive: true
    glob: "**/*.html.erb"
EOF

      stdout, _, status = shell(goodcheck, "pattern", chdir: builder.path)

      assert status.success?
      assert_match "sample.foo", stdout
      assert_match "sample.bar", stdout

      stdout, _, status = shell(goodcheck, "pattern", "sample.foo", chdir: builder.path)

      assert status.success?
      assert_match "sample.foo", stdout
      refute_match "sample.bar", stdout

      stdout, _, status = shell(goodcheck, "pattern", "sample", chdir: builder.path)

      assert status.success?
      assert_match "sample.foo", stdout
      assert_match "sample.bar", stdout

      stdout, _, status = shell(goodcheck, "pattern", "foo", chdir: builder.path)

      assert status.success?
      refute_match "sample.foo", stdout
      refute_match "sample.bar", stdout
    end
  end
end
