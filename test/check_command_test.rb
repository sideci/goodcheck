require "test_helper"

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
    severity: warning
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
        assert_equal <<OUT, stdout.string
app/models/user.rb:2:15: Foo  (foo)  [warning]
  belongs_to :foo
              ^~~

3 files inspected, 1 issue detected
OUT
      end
    end
  end

  def test_check_multiline
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern:
      regexp: "<p>.+</p>"
      multiline: true
    glob: "*.html"
EOF

      builder.file name: Pathname("test.html"), content: <<EOF
<section>
  <p>
    Geckos are a group of usually small, usually nocturnal lizards.
  </p>
</section>
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
test.html:2:3: Foo  (foo)
  <p>
  ^~~

2 files inspected, 1 issue detected
OUT
      end
    end
  end

  def test_check_multiline_json
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
    severity: warning
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
                         location: { start_line: 1, start_column: 1, end_line: 3, end_column: 4 },
                         message: "Foo",
                         justifications: [],
                         severity: "warning"
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
        assert_empty stderr.string
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

      builder.file name: Pathname("Gemfile"), content: <<EOF
source "https://rubygems.org"
EOF
      builder.file name: Pathname("package.json"), content: <<EOF
{}
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
package.json:-:-: Foo  (foo)

2 files inspected, 1 issue detected
OUT
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
        assert_equal <<OUT, stdout.string
goodcheck.yml:3:14: Do you want to write GitHub?  (com.example.1)
    pattern: Github
             ^~~~~~
test.yml:1:7: Do you want to write GitHub?  (com.example.1)
text: Github
      ^~~~~~

2 files inspected, 2 issues detected
OUT
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
        assert_equal <<OUT, stdout.string
goodcheck.yml:3:14: Do you want to write GitHub?  (com.example.1)
    pattern: Github
             ^~~~~~

1 file inspected, 1 issue detected
OUT
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
        assert_empty stdout.string
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
        assert_empty stdout.string
        assert_equal <<ERR, stderr.string
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
    "import": optional(array(string)),
    "exclude": optional(enum(array(string), string)),
    "exclude_binary": optional(boolean),
    "severity": optional(severity)
  }
  positive_rule = {
    "id": string,
    "pattern": enum(array(pattern), pattern),
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": optional(glob),
    "pass": optional(enum(array(string), string)),
    "fail": optional(enum(array(string), string)),
    "severity": optional(string)
  }
  negative_rule = {
    "id": string,
    "not": { "pattern": enum(array(pattern), pattern) },
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": optional(glob),
    "pass": optional(enum(array(string), string)),
    "fail": optional(enum(array(string), string)),
    "severity": optional(string)
  }
  nopattern_rule = {
    "id": string,
    "message": string,
    "justification": optional(enum(array(string), string)),
    "glob": glob,
    "severity": optional(string)
  }
  triggered_rule = {
    "id": string,
    "message": string,
    "justification": optional(enum(array(string), string)),
    "trigger": enum(array(trigger), trigger),
    "severity": optional(string)
  }
ERR
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

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
hello.css:6:3: Foo  (foo)
  background-color: pink;
  ^~~~~~~~~~~~~~~~~~~~~~~

1 file inspected, 1 issue detected
OUT
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
        assert_equal <<OUT, stdout.string

no files inspected, no issues detected
OUT
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
      - pattern: euc_jp.*
        encoding: EUC-JP
      - pattern: utf_8.*
EOF

      builder.file name: Pathname("euc_jp.txt"), content: <<EOF.encode("EUC-JP")
吾輩は猫である。
EOF

      builder.file name: Pathname("utf_8.txt"), content: <<EOF.encode("UTF-8")
吾輩は猫である。
EOF

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
euc_jp.txt:1:10: Foo  (foo)
吾輩は猫である。
         ^~~
utf_8.txt:1:10: Foo  (foo)
吾輩は猫である。
         ^~~

3 files inspected, 2 issues detected
OUT
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
        assert_equal <<OUT, stdout.string
goodcheck.yml:4:14: Foo  (foo)
    pattern: 猫
             ^~~
text_file:1:1: Foo  (foo)
猫ねこ🐈
^~~

3 files inspected, 2 issues detected
OUT
        assert_equal <<ERR, stderr.string
binary_file: #<ArgumentError: invalid byte sequence in UTF-8>
ERR
      end
    end
  end

  def test_no_config
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: Pathname("foo.yml"), rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 1, check.run
        assert_equal "Configuration file not found: foo.yml\n", stderr.string
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
          assert_equal <<OUT, stdout.string
README.md:1:1: Foo  (foo)
foo
^~~

1 file inspected, 1 issue detected
OUT
        end

        stdout.reopen("")
        stderr.reopen("")
        reporter = Reporters::Text.new(stdout: stdout)
        Check.new(config_path: builder.config_path.basename, rules: [], targets: [Pathname("."), Pathname("goodcheck.yml")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal <<OUT, stdout.string
README.md:1:1: Foo  (foo)
foo
^~~
goodcheck.yml:2:9: Foo  (foo)
  - id: foo
        ^~~
goodcheck.yml:4:14: Foo  (foo)
    pattern: foo
             ^~~

2 files inspected, 3 issues detected
OUT
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
          assert_equal <<OUT, stdout.string
.file:1:1: Foo  (foo)
foo
^~~
goodcheck.yml:2:9: Foo  (foo)
  - id: foo
        ^~~
goodcheck.yml:4:14: Foo  (foo)
    pattern: foo
             ^~~

2 files inspected, 3 issues detected
OUT
        end

        stdout.reopen("")
        stderr.reopen("")
        reporter = Reporters::Text.new(stdout: stdout)
        Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("."), Pathname(".file")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home").tap do |check|
          assert_equal 2, check.run
          assert_equal <<OUT, stdout.string
.file:1:1: Foo  (foo)
foo
^~~
goodcheck.yml:2:9: Foo  (foo)
  - id: foo
        ^~~
goodcheck.yml:4:14: Foo  (foo)
    pattern: foo
             ^~~
.file:1:1: Foo  (foo)
foo
^~~

3 files inspected, 4 issues detected
OUT
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
          assert_equal <<OUT, stdout.string
goodcheck.yml:4:14: Some message  (some_rule)
    pattern: foo
             ^~~

1 file inspected, 1 issue detected
OUT
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
          assert_equal <<OUT, stdout.string
goodcheck.yml:4:14: Some message  (some_rule)
    pattern: foo
             ^~~

1 file inspected, 1 issue detected
OUT
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
          assert_equal <<OUT, stdout.string
goodcheck.yml:4:14: Some message  (some_rule)
    pattern: foo
             ^~~

1 file inspected, 1 issue detected
OUT
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
          assert_equal <<OUT, stdout.string
abc.txt:1:1: Foo  (foo)
foo
^~~~

1 file inspected, 1 issue detected
OUT
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
                         location: { start_line: 1, start_column: 11, end_line: 1, end_column: 17 },
                         message: "Require",
                         justifications: [],
                         severity: nil
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
        assert_empty stderr.string
      end

      builder.cd do
        stdout.reopen("")
        stderr.reopen("")
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
                         location: { start_line: 1, start_column: 11, end_line: 1, end_column: 17 },
                         message: "Require",
                         justifications: [],
                         severity: nil
                       }
                     ], JSON.parse(stdout.string, symbolize_names: true)
        assert_empty stderr.string
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
          assert_equal <<OUT, stdout.string
x.js:-:-: Use *strict mode* if possible.  (strict-mode)

1 file inspected, 1 issue detected
OUT
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

      builder.file name: Pathname("app/models/user.rb"), content: <<EOF
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
          location: { start_line: 4, start_column: 15, end_line: 4, end_column: 17 },
          message: "Foo",
          justifications: [],
          severity: nil
        }], JSON.parse(stdout.string, symbolize_names: true)
        assert_empty stderr.string
      end
    end
  end

  def test_missing_rule
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        builder.config content: <<EOF
rules:
  - id: foo
    message: Foo
    pattern: foo
EOF

        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: ["foo", "bar", "baz"], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 1, check.run
        assert_empty stdout.string
        assert_equal <<ERR, stderr.string
missing rule: bar
missing rule: baz
ERR
      end
    end
  end

  def test_glob_exclude
    TestCaseBuilder.tmpdir do |builder|
      builder.config content: <<EOF
rules:
  - id: com.example.1
    pattern: foo
    message: Disallow `foo`
    glob:
      - { pattern: "**/*.txt", exclude: ["**/*test*/**", "*bar*"] }
EOF

      builder.file name: Pathname("test.txt"), content: "foo"
      builder.file name: Pathname("test/a.txt"), content: "foo"
      builder.file name: Pathname("a/__tests__/b.txt"), content: "foo"
      builder.file name: Pathname("_bar_.txt"), content: "foo"
      builder.file name: Pathname("a/b/bar.txt"), content: "foo"
      builder.file name: Pathname("pass.txt"), content: "foo"

      builder.cd do
        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname(".")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
a/b/bar.txt:1:1: Disallow `foo`  (com.example.1)
foo
^~~
pass.txt:1:1: Disallow `foo`  (com.example.1)
foo
^~~
test.txt:1:1: Disallow `foo`  (com.example.1)
foo
^~~

7 files inspected, 3 issues detected
OUT
      end
    end
  end

  def test_justification
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        builder.config content: <<EOF
rules:
  - id: foo_rule
    message: Foo
    pattern: foo
    justification:
      - AAA
      - BBB
EOF

        builder.file name: Pathname("test.txt"), content: "    foo"

        reporter = Reporters::Text.new(stdout: stdout)
        check = Check.new(config_path: builder.config_path, rules: [], targets: [Pathname("test.txt")], reporter: reporter, stderr: stderr, force_download: false, home_path: builder.path + "home")

        assert_equal 2, check.run
        assert_equal <<OUT, stdout.string
test.txt:1:5: Foo  (foo_rule)
    foo
    ^~~

  Justifications:
    • AAA
    • BBB


1 file inspected, 1 issue detected
OUT
      end
    end
  end
end
