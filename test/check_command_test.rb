require_relative "test_helper"

class CheckCommandTest < Minitest::Test
  include Outputs

  Check = Goodcheck::Commands::Check
  Reporters = Goodcheck::Reporters

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

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run

        refute_match %r(app/models/user\.rb:1:class User < ApplicationRecord), stdout.string
        assert_match %r(app/models/user\.rb:2:  belongs_to :foo:\tFoo), stdout.string
        refute_match %r(app/views/welcome/index\.html\.erb), stdout.string
      end
    end
  end

  def test_symlink_check
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: com.example.1
    pattern: Github
    message: Do you want to write GitHub?
EOF

      builder.file name: Pathname("test.yml"), content: <<EOF
text: Github
EOF

      builder.symlink name: Pathname("link.yml"), original: Pathname("test.yml")

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run

        assert_match %r(test\.yml:1:text: Github), stdout.string
        refute_match %r(link\.yml:1:text: Github), stdout.string
      end
    end
  end

  def test_broken_symlink_check
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: com.example.1
    pattern: Github
    message: Do you want to write GitHub?
EOF

      builder.file name: Pathname("test.yml"), content: <<EOF
text: Github
EOF

      builder.symlink name: Pathname("link.yml"), original: Pathname("test.yml")

      builder.cd do
        # Break `link.yml`
        Pathname("test.yml").delete

        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
      end
    end
  end

  def test_broken_yaml_error
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
      pattern:
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 1, check.run

        assert_match /Unexpected error happens while loading YAML file: #<Psych::SyntaxError:/, stderr.string
      end
    end
  end

  def test_invalid_config
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 1, check.run

        assert_match /Invalid config at \[rules\]\[0\]\[pattern\]/, stderr.string
      end
    end
  end

  def test_no_match
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: foo
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 0, check.run
      end
    end
  end

  def test_encoding
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: 猫
    glob:
      - pattern: euc-jp
        encoding: EUC-JP
      - pattern: utf-8
EOF

      builder.file name: Pathname("euc-jp"), content: <<EOF.encode("EUC-JP")
吾輩は猫である。
EOF

      builder.file name: Pathname("utf-8"), content: <<EOF
吾輩は猫である。
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run

        assert_match %r(euc-jp:1:吾輩は猫である。), stdout.string
        assert_match %r(utf-8:1:吾輩は猫である。), stdout.string
      end
    end
  end

  def test_encoding_error
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: 猫
EOF

      builder.file name: Pathname("binary_file"), content: SecureRandom.gen_random(100)
      builder.file name: Pathname("text_file"), content: "猫ねこ🐈"

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run

        assert_match %r(binary_file: #<ArgumentError: invalid byte sequence in UTF-8>), stderr.string
        assert_match %r(text_file:1:猫ねこ🐈:\tFoo), stdout.string
      end
    end
  end

  def test_no_config
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 1, check.run

        assert_match /No such file or directory @ rb_sysopen/, stderr.string
      end
    end
  end

  def test_check_ignores_config
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname("README.md"), content: "foo"
        builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: foo
EOF

        Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run

          assert_match /README.md/, stdout.string
          refute_match /goodcheck.yml/, stdout.string
        end

        Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname("."), Pathname("goodcheck.yml")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run

          assert_match /README.md/, stdout.string
          assert_match /goodcheck.yml/, stdout.string
        end
      end
    end
  end

  def test_check_ignores_dot_files
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname(".file"), content: "foo"
        builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: foo
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          refute_match /\.file/, stdout.string
        end

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("."), Pathname(".file")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_match /\.file/, stdout.string
        end
      end
    end
  end
end
