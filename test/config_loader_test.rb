require "test_helper"

class ConfigLoaderTest < Minitest::Test
  include Assertions
  include TestHelper

  ConfigLoader = Goodcheck::ConfigLoader
  Rule = Goodcheck::Rule
  ImportLoader = Goodcheck::ImportLoader
  Pattern = Goodcheck::Pattern

  def stderr
    @stderr ||= StringIO.new
  end

  def config_path
    Pathname("hello.yml")
  end

  def setup
    super
    self.cache_path = Pathname.new(Dir.mktmpdir)
  end

  def teardown
    super
    self.cache_path.rmtree
  end

  attr_accessor :cache_path

  def import_loader
    @import_loader ||= ImportLoader.new(expires_in: 30,
                                        config_path: config_path,
                                        force_download: false,
                                        cache_path: cache_path)
  end

  def config_loader
    ConfigLoader.new(path: config_path, content: "", stderr: stderr, import_loader: import_loader)
  end

  def test_load_pattern_string
    loader = config_loader()
    pattern = loader.load_pattern "foo.bar"

    assert_pattern pattern, regexp: /foo\.bar/, source: "foo.bar"
  end

  def test_load_pattern_string_regexp
    loader = config_loader()

    loader.load_pattern("/hello/").tap do |pattern|
      assert_pattern pattern, regexp: /hello/, source: "/hello/"
    end

    loader.load_pattern("/hello/mi").tap do |pattern|
      assert_pattern pattern, regexp: /hello/mi, source: "/hello/mi"
    end
  end

  def test_load_literal_pattern_hash_ci
    loader = config_loader()
    pattern = loader.load_pattern({ literal: "foo.bar", case_insensitive: true })

    assert_pattern pattern, regexp: /foo\.bar/i, source: "foo.bar"
  end

  def test_load_literal_pattern_hash_cs
    loader = config_loader()
    pattern = loader.load_pattern({ literal: "foo.bar", case_insensitive: false })

    assert_pattern pattern, regexp: /foo\.bar/, source: "foo.bar"
  end

  def test_load_regexp_pattern
    loader = config_loader()
    pattern = loader.load_pattern({ regexp: "foo.bar" })

    assert_pattern pattern, regexp: /foo.bar/, source: "foo.bar"
  end

  def test_load_regexp_pattern_ci_multi
    loader = config_loader()
    pattern = loader.load_pattern({ regexp: "foo.bar", case_insensitive: true, multiline: true })

    assert_pattern pattern, regexp: /foo.bar/im, source: "foo.bar"
  end

  def test_load_token_pattern
    loader = config_loader()
    pattern = loader.load_pattern({ token: "foo.bar" })

    assert_pattern pattern, regexp: /\bfoo\s*\.\s*bar\b/m, source: "foo.bar"
  end

  def test_load_globs
    loader = config_loader()

    g1, g2, g3, g4 = loader.load_globs([
      "foo",
      { pattern: "foo/bar" },
      { pattern: "*.rb", encoding: "Shift_JIS" },
      { pattern: "lib/**/*", exclude: "*baz*" },
    ])

    assert_equal "foo", g1.pattern
    assert_nil g1.encoding
    assert_nil g1.exclude

    assert_equal "foo/bar", g2.pattern
    assert_nil g2.encoding
    assert_nil g2.exclude

    assert_equal "*.rb", g3.pattern
    assert_equal "Shift_JIS", g3.encoding
    assert_nil g3.exclude

    assert_equal "lib/**/*", g4.pattern
    assert_nil g4.encoding
    assert_equal "*baz*", g4.exclude
  end

  def test_load_pattern_rule
    loader = config_loader()
    rule = loader.load_rule({ id: "com.id.1", message: "Some message", pattern: "foo.bar" })

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal [], rule.justifications
    rule.triggers[0].tap do |trigger|
      assert_operator trigger, :by_pattern?
      assert_equal ["foo.bar"], trigger.patterns.map(&:source)
      assert_equal [], trigger.globs
      assert_equal [], trigger.passes
      assert_equal [], trigger.fails
      refute_operator trigger, :negated?
    end
  end

  def test_load_pattern_rule_case
    loader = config_loader()
    rule = loader.load_rule({
                              id: "com.id.1",
                              message: "Some message",
                              pattern: [
                                {
                                  literal: "foo.bar",
                                },
                                {
                                  literal: "foo.bar.baz",
                                  case_insensitive: true,
                                },
                                {
                                  literal: "foo",
                                  case_sensitive: false
                                }
                              ]
                            })

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal [], rule.justifications

    rule.triggers[0].tap do |trigger|
      assert_operator trigger, :by_pattern?
      assert_equal [/foo\.bar/, /foo\.bar\.baz/i, /foo/i], trigger.patterns.map(&:regexp)
      assert_equal [], trigger.globs
      assert_equal [], trigger.passes
      assert_equal [], trigger.fails
    end
  end

  def test_load_pattern_and_glob
    loader = config_loader()
    rule = loader.load_rule(
      {
        id: "com.id.1",
        message: "Some message",
        pattern: [
          { literal: "foo.bar", glob: "*.rb" },
          { literal: "File.open", glob: "*.rb" },
          { literal: "background-color" },
          { literal: "margin-left" }
        ],
        glob: ["app/**/*"],
        pass: ["hogehoge"],
        fail: ["foo.bar.baz"]
      }
    )

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal [], rule.justifications

    # Make triggers for each glob
    assert_equal 3, rule.triggers.size

    rule.triggers[0].tap do |trigger|
      assert_operator trigger, :by_pattern?
      assert_equal ["foo.bar"], trigger.patterns.map(&:source)
      assert_equal [Goodcheck::Glob.new(pattern: "*.rb", encoding: nil, exclude: nil)], trigger.globs
      assert_equal ["hogehoge"], trigger.passes
      assert_operator trigger, :skips_fail_examples?
      assert_equal [], trigger.fails
      refute_operator trigger, :negated?
    end

    rule.triggers[1].tap do |trigger|
      assert_operator trigger, :by_pattern?
      assert_equal ["File.open"], trigger.patterns.map(&:source)
      assert_equal [Goodcheck::Glob.new(pattern: "*.rb", encoding: nil, exclude: nil)], trigger.globs
      assert_equal ["hogehoge"], trigger.passes
      assert_operator trigger, :skips_fail_examples?
      assert_equal [], trigger.fails
      refute_operator trigger, :negated?
    end

    rule.triggers[2].tap do |trigger|
      assert_operator trigger, :by_pattern?
      assert_equal ["background-color", "margin-left"], trigger.patterns.map(&:source)
      assert_equal [Goodcheck::Glob.new(pattern: "app/**/*", encoding: nil, exclude: nil)], trigger.globs
      assert_equal ["hogehoge"], trigger.passes
      assert_operator trigger, :skips_fail_examples?
      assert_equal [], trigger.fails
      refute_operator trigger, :negated?
    end
  end

  def test_load_rule_trigger
    loader = config_loader()
    rule = loader.load_rule(
      {
        id: "com.id.1",
        message: "Some message",
        trigger: [
          {
            pattern: "foo.bar",
            glob: ["*.rb"],
            pass: ["foo.baz"],
            fail: ["foo.bar.baz"]
          }
        ]
      }
    )

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal [], rule.justifications
    rule.triggers[0].tap do |trigger|
      refute_operator trigger, :by_pattern?
      assert_equal ["foo.bar"], trigger.patterns.map(&:source)
      assert_equal [Goodcheck::Glob.new(pattern: "*.rb", encoding: nil, exclude: nil)], trigger.globs
      assert_equal ["foo.baz"], trigger.passes
      assert_equal ["foo.bar.baz"], trigger.fails
      refute_operator trigger, :negated?
    end
  end

  def test_load_rule_case_warning
    loader = config_loader()
    loader.load_rule({
                       id: "com.id.1",
                       message: "Some message",
                       pattern: [
                         {
                           literal: "foo",
                           case_insensitive: true,
                         },
                         {
                           literal: "foo.bar",
                           case_insensitive: true,
                         },
                       ]
                     })

    assert_match %r(`case_insensitive` option is deprecated), stderr.string
    assert_equal 1, stderr.string.scan(/`case_insensitive` option is deprecated/).count
  end

  def test_load_rule_negated
    loader = config_loader()
    rule = loader.load_rule(
      {
        id: "com.id.1",
        message: "Some message",
        not: {
          pattern: "foo.bar"
        }
      }
    )

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal [], rule.justifications

    rule.triggers[0].tap do |trigger|
      assert_equal ["foo.bar"], trigger.patterns.map(&:source)
      assert_equal [], trigger.globs
      assert_equal [], trigger.passes
      assert_equal [], trigger.fails
      assert_operator trigger, :negated?
    end
  end

  def test_load_config_failure
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: [{}], stderr: stderr, import_loader: import_loader)
    assert_raises StrongJSON::Type::TypeError do
      loader.load
    end
  end

  def test_load_exclude
    loader = ConfigLoader.new(
      path: Pathname("hello.yml"),
      content: {
        rules: [],
        exclude: ["**/node_modules"]
      },
      stderr: stderr,
      import_loader: import_loader
    )
    config = loader.load
    assert_equal ["**/node_modules"], config.exclude_paths
  end

  def test_load_exclude_string
    loader = ConfigLoader.new(
      path: Pathname("hello.yml"),
      content: {
        rules: [],
        exclude: "**/node_modules"
      },
      stderr: stderr,
      import_loader: import_loader
    )
    config = loader.load
    assert_equal ["**/node_modules"], config.exclude_paths
  end

  def test_load_config_failure2
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "a string", stderr: stderr, import_loader: import_loader)

    assert_raises StrongJSON::Type::TypeError do
      loader.load
    end
  end

  def test_load_encoding_failure
    loader = ConfigLoader.new(path: Pathname("hello.yml"),
                              content: {
                                rules: [
                                  {
                                    id: "foo",
                                    pattern: "bar",
                                    message: "baz",
                                    glob: { pattern: "*.rb", encoding: "UNKNOWN_ENCODING😍"}
                                  }
                                ]
                              },
                              stderr: stderr,
                              import_loader: import_loader)

    assert_raises StrongJSON::Type::TypeError do
      loader.load
    end
  end

  def test_load_config
    loader = ConfigLoader.new(path: Pathname("hello.yml"),
                              content: {
                                rules: [
                                  {
                                    id: "foo",
                                    pattern: "string",
                                    message: "Hello",
                                  },
                                  {
                                    id: "bar",
                                    pattern: "string",
                                    message: "Hello",
                                    justification: ["Some reason"],
                                    glob: [
                                      "**/*.rb",
                                      { pattern: "**/Rakefile", encoding: "EUC-JP" },
                                      { pattern: "*.gemspec" },
                                      { pattern: "*.md", exclude: "*CHANGELOG*" }
                                    ],
                                    pass: ["hoge"],
                                    fail: ["huga"]
                                  },
                                  {
                                    id: "baz",
                                    pattern:
                                      [
                                        { regexp: "hoge" },
                                        { literal: "foo" },
                                        { token: "bar" }
                                      ],
                                    message: "Hello World",
                                    justification: "a reason",
                                    glob: "foo",
                                    pass: "hoge",
                                    fail: "baz"
                                  }
                                ]
                              },
                              stderr: stderr,
                              import_loader: import_loader)

    loader.load
  end

  def test_load_import
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      rules_path = path + "rules.yml"
      rules_path.write <<EOF
- id: imported_rule
  message: This is imported rule
  pattern: Imported
EOF

      cache_path = path + "cache"
      cache_path.mkpath

      import_loader = ImportLoader.new(config_path: config_path,
                                       cache_path: cache_path,
                                       expires_in: 30,
                                       force_download: true)

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [],
          import: ["rules.yml"]
        },
        stderr: stderr,
        import_loader: import_loader
      )

      config = loader.load

      assert config.rules.any? {|rule| rule.id == "imported_rule" }
    end
  end

  def test_no_pattern_rule
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [
            {
              id: "1",
              message: "foo",
              glob: "db/schema.rb"
            },
          ],
        },
        stderr: stderr,
        import_loader: import_loader
      )

      config = loader.load

      config.rules.find {|rule| rule.id == "1" }.tap do |rule|
        rule.triggers[0].tap do |trigger|
          assert_equal [], trigger.patterns
          assert_equal ["db/schema.rb"], trigger.globs.map(&:pattern)
        end
      end
    end
  end

  def test_var_pattern_true
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [
            {
              id: "1",
              message: "foo",
              glob: "db/schema.rb"
            },
          ],
        },
        stderr: stderr,
        import_loader: import_loader
      )

      pattern = loader.load_var_pattern(true)
      assert_instance_of Pattern::Token::VarPattern, pattern
      assert_equal [], pattern.patterns
      refute pattern.negated
    end
  end

  def test_var_pattern_patterns
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [
            {
              id: "1",
              message: "foo",
              glob: "db/schema.rb"
            },
          ],
        },
        stderr: stderr,
        import_loader: import_loader
      )

      pattern = loader.load_var_pattern(
        [
          "hello",
          "/.*/",
          "/.*a.*/mi",
          3
        ]
      )
      assert_instance_of Pattern::Token::VarPattern, pattern
      assert_equal [
                     "hello",
                     /.*/,
                     /.*a.*/mi,
                     3
                   ], pattern.patterns
      refute pattern.negated
    end
  end

  def test_var_pattern_negated
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [
            {
              id: "1",
              message: "foo",
              glob: "db/schema.rb"
            },
          ],
        },
        stderr: stderr,
        import_loader: import_loader
      )

      pattern = loader.load_var_pattern(
        {
          not: [
            "hello",
            "/.*/",
            "/.*a.*/mi",
            3
          ]
        }
      )
      assert_instance_of Pattern::Token::VarPattern, pattern
      assert_equal [
                     "hello",
                     /.*/,
                     /.*a.*/mi,
                     3
                   ], pattern.patterns
      assert pattern.negated
    end
  end

  def test_token_pattern_with_vars
    mktmpdir do |path|
      config_path = path + "goodcheck.yml"

      loader = ConfigLoader.new(
        path: config_path,
        content: {
          rules: [
            {
              id: "1",
              message: "foo",
              glob: "db/schema.rb"
            },
          ],
        },
        stderr: stderr,
        import_loader: import_loader
      )

      pattern = loader.load_pattern(
        {
          token: "bgcolor={${color:string}}",
          where: {
            color: {
              not: [
                "pink"
              ]
            }
          }
        }
      )

      assert_instance_of Pattern::Token, pattern
      assert_equal %r(\bbgcolor\s*=\s*\{(?-mix:(?-mix:"(?<color>(?:[^"]|\")*)")|(?-mix:'(?<color>(?:[^']|\')*)'))\})m, pattern.regexp
      assert_equal [:color], pattern.variables.keys
      pattern.variables[:color].tap do |color|
        assert_equal ["pink"], color.patterns
        assert color.negated
      end
    end
  end

  def test_token_pattern_types
    where = ConfigLoader::Schema.where

    assert_match(where, {})
    assert_match(where, { color: true })
    assert_match(where, { color: "pink" })
    assert_match(where, { size: [1,2,3] })
    assert_match(where, { color: { not: [1,2,3] } })
  end

  def test_config_no_rules
    loader = ConfigLoader.new(
      path: Pathname("hello.yml"),
      content: {},
      stderr: stderr,
      import_loader: import_loader
    )

    config = loader.load
    assert_empty config.rules
  end

  def test_config_with_invalid_pattern
    loader = ConfigLoader.new(
      path: Pathname("hello.yml"),
      content: {
        rules: [{ id: "foo1", pattern: "/[a/", message: "Foo" }],
      },
      stderr: stderr,
      import_loader: import_loader
    )

    error = assert_raises ConfigLoader::InvalidPattern do
      loader.load
    end
    assert_equal "Invalid pattern of the `foo1` rule in `hello.yml`: premature end of char-class: /[a/", error.message
  end
end
