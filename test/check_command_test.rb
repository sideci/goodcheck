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

  def test_check2
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      regexp: .+
      multiline: true
    glob:
      - "app/models/**/*.rb"
EOF

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
class User < ApplicationRecord
  belongs_to :foo
end
EOF

      builder.cd do
        reporter = Reporters::JSON.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run

        assert_equal [
                       {
                         rule_id: "foo",
                         path: "app/models/user.rb",
                         location: { start_line: 1, start_column: 0, end_line: 4, end_column: 0 },
                         message: "Foo",
                         justifications: []
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
      end
    end
  end

  def test_check_no_pattern
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    glob: "package.json"
EOF

      builder.file name: Pathname("Gemfile"), content: <<-EOF
source "https://rubygems.org"
      EOF
      builder.file name: Pathname("package.json"), content: <<-EOF
{}
      EOF

      builder.cd do

        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal "package.json:-:{}:\tFoo\n", stdout.string
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

        assert_match %r(Unexpected error happens while loading YAML file: #<Psych::SyntaxError:), stderr.string
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

        assert_equal <<MSG, stderr.string
Invalid config: TypeError at $.rules[0]: expected=rule, value={:id=>"foo", :message=>"Foo"}
 0 expected to be rule
  Expected to be rules
   "rules" expected to be optional(rules)
    $ expected to be config

Where:
  rule = enum(positive_rule, negative_rule, nopattern_rule, triggered_rule)
  rules = array(rule)
  config = {
    "rules": optional(rules),
    "import": optional(imports),
    "exclude": optional(exclude)
  }
  positive_rule = {
    "id": string,
    "pattern": enum(array(pattern), pattern),
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": optional(glob),
    "pass": optional(enum(array(string), string)),
    "fail": optional(enum(array(string), string))
  }
  negative_rule = {
    "id": string,
    "not": { "pattern": enum(array(pattern), pattern) },
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": optional(glob),
    "pass": optional(enum(array(string), string)),
    "fail": optional(enum(array(string), string))
  }
  nopattern_rule = {
    "id": string,
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": glob
  }
  triggered_rule = {
    "id": string,
    "message": string,
    "justification": optional(enum(array(string), string)),
    "trigger": enum(array(trigger), trigger)
  }
MSG
      end
    end
  end

  def test_token_variable_match
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      - token: "background-color: ${color:word};"
        where:
          color:
            - /ink/
            - gray
EOF

      builder.file name: Pathname("hello.css"), content: <<EOF
div.icon {
  background-color: white;
}

div.size {
  background-color: pink;
}
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        result = check.run

        assert_equal 2, result
        assert_equal <<MSG, stdout.string
hello.css:6:  background-color: pink;:\tFoo
MSG
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

        assert_match %r(No such file or directory @ rb_sysopen), stderr.string
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

          assert_match %r(README\.md), stdout.string
          refute_match %r(goodcheck\.yml), stdout.string
        end

        Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname("."), Pathname("goodcheck.yml")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run

          assert_match %r(README\.md), stdout.string
          assert_match %r(goodcheck\.yml), stdout.string
        end
      end
    end
  end

  def test_check_dot_files
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
          assert_match %r(\.file), stdout.string
        end

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("."), Pathname(".file")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_match %r(\.file), stdout.string
        end
      end
    end
  end

  def test_default_exclusions_dot_git
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname(".git/abc.txt"), content: "foo"
        builder.config content: <<EOF
rules:
  - id: some_rule
    message: Some message
    pattern: foo
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal "goodcheck.yml:4:    pattern: foo:\tSome message\n", stdout.string
        end
      end
    end
  end

  def test_default_exclusions_dot_svn
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname(".svn/abc.txt"), content: "foo"
        builder.config content: <<EOF
rules:
  - id: some_rule
    message: Some message
    pattern: foo
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal "goodcheck.yml:4:    pattern: foo:\tSome message\n", stdout.string
        end
      end
    end
  end

  def test_default_exclusions_dot_hg
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname(".hg/abc.txt"), content: "foo"
        builder.config content: <<EOF
rules:
  - id: some_rule
    message: Some message
    pattern: foo
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal "goodcheck.yml:4:    pattern: foo:\tSome message\n", stdout.string
        end
      end
    end
  end

  def test_pattern_end_of_line
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname("abc.txt"), content: "foo\r\n"
        builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      regexp: "foo.*"
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("abc.txt")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal "abc.txt:1:foo:\tFoo\n", stdout.string
        end
      end
    end
  end

  def test_check_excluded
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: require
    message: Require
    pattern: require
    glob:
      - "**/*.js"

exclude:
  - node_modules
EOF

      builder.file name: Pathname("hello.js"), content: <<EOF
const a = require("node")
EOF

      builder.file name: Pathname("node_modules/bar.js"), content: <<EOF
const a = require("node")
EOF

      builder.cd do
        reporter = Reporters::JSON.new(stdout: stdout, stderr: stderr)
        check = Check.new(
          config_path: builder.config_path,
          rules: [],
          targets: [Pathname(".")],
          reporter: reporter,
          stderr: stderr,
          force_download: false,
          home_path: builder.path + "home"
        )

        assert_equal 2, check.run

        assert_equal [
                       {
                         rule_id: "require",
                         path: "hello.js",
                         location: { start_line: 1, start_column: 10, end_line: 1, end_column: 17 },
                         message: "Require",
                         justifications: []
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
      end

      @stdout = nil

      builder.cd do
        reporter = Reporters::JSON.new(stdout: stdout, stderr: stderr)
        check = Check.new(
          config_path: builder.config_path,
          rules: [],
          targets: [Pathname("node_modules")],
          reporter: reporter,
          stderr: stderr,
          force_download: false,
          home_path: builder.path + "home"
        )

        assert_equal 2, check.run

        assert_equal [
                       {
                         rule_id: "require",
                         path: "node_modules/bar.js",
                         location: { start_line: 1, start_column: 10, end_line: 1, end_column: 17 },
                         message: "Require",
                         justifications: []
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
      end
    end
  end

  def test_not_pattern_on_empty_file
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        builder.file name: Pathname("x.js"), content: ""
        builder.config content: <<EOF
rules:
  - id: strict-mode
    not:
      pattern: use strict
    message: Use *strict mode* if possible.
EOF

        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("x.js")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal "x.js:-:-:\tUse *strict mode* if possible.\n", stdout.string
        end
      end
    end
  end

  def test_disabled_lines_report_no_issue
    puts "STARTING BROKEN TEST"
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

      builder.file name: Pathname("app/models/user.rb"), content: <<-EOF
class User < ApplicationRecord
  # goodcheck-disable-next-line
  belongs_to :foo
  belongs_to :bar
end
EOF


      builder.cd do
        reporter = Reporters::JSON.new(stdout: stdout, stderr: stderr)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal [{
          rule_id: "foo",
          path: "app/models/user.rb",
          location: { start_line: 4, start_column: 14, end_line: 4, end_column: 17 },
          message: "Foo",
          justifications: []
        }], JSON.parse(stdout.string, symbolize_names: true)
      end
    end
  end
end
