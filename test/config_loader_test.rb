require_relative "test_helper"

class ConfigLoaderTest < Minitest::Test
  include Assertions
  include TestHelper

  ConfigLoader = Goodcheck::ConfigLoader
  Rule = Goodcheck::Rule
  ImportLoader = Goodcheck::ImportLoader

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

    g1, g2, g3, _ = loader.load_globs(["foo", { pattern: "foo/bar" }, { pattern: "*.rb", encoding: "Shift_JIS" }])

    assert_equal "foo", g1.pattern
    assert_nil g1.encoding

    assert_equal "foo/bar", g2.pattern
    assert_nil g2.encoding

    assert_equal "*.rb", g3.pattern
    assert_equal "Shift_JIS", g3.encoding
  end

  def test_load_rule
    loader = config_loader()
    rule = loader.load_rule({ id: "com.id.1", message: "Some message", pattern: "foo.bar" })

    assert_instance_of Rule, rule
    assert_equal "com.id.1", rule.id
    assert_equal "Some message", rule.message
    assert_equal ["foo\\.bar"], rule.patterns.map(&:source)
    assert_equal [], rule.justifications
    assert_equal [], rule.globs
    assert_equal [], rule.passes
    assert_equal [], rule.fails
  end

  def test_load_rule_case
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
    assert_equal [/foo\.bar/, /foo\.bar\.baz|foo/i], rule.patterns.map(&:regexp)
    assert_equal [], rule.justifications
    assert_equal [], rule.globs
    assert_equal [], rule.passes
    assert_equal [], rule.fails
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

    assert_match /`case_insensitive` option is deprecated/, stderr.string
    assert_equal 1, stderr.string.scan(/`case_insensitive` option is deprecated/).count
  end

  def test_load_config_failure
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: [{}], stderr: stderr, import_loader: import_loader)
    assert_raises StrongJSON::Type::Error do
      loader.load
    end
  end

  def test_load_config_failure2
    loader = ConfigLoader.new(path: Pathname("hello.yml"), content: "a string", stderr: stderr, import_loader: import_loader)

    assert_raises StrongJSON::Type::Error do
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
                                    glob: { pattern: "*.rb", encoding: "UNKNOWN_ENCODING😍" }
                                  }
                                ]
                              },
                              stderr: stderr,
                              import_loader: import_loader)

    exn = nil
    begin
      loader.load
    rescue => exn
    end

    assert_equal [:rules, 0, :glob], exn.path
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
                                      { pattern: "*.gemspec" }
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

      assert config.rules.any? { |rule| rule.id == "imported_rule" }
    end
  end
end
