require "test_helper"

class ConfigTest < Minitest::Test
  include TestHelper

  ConfigLoader = Goodcheck::ConfigLoader
  Config = Goodcheck::Config

  def stderr
    @stderr ||= StringIO.new
  end

  def test_rules_for_path
    loader = ConfigLoader.new(path: nil, content: nil, stderr: stderr, import_loader: nil)

    config = Config.new(
      rules: [
        loader.load_rule({ id: "rule1", glob: ["**/*.rb"], message: "" }),
        loader.load_rule({ id: "rule2", glob: ["*.rb", "app/views/**/*.html.erb"], message: "" }),
        loader.load_rule({ id: "rule3", glob: ["app/**/*.rb"], message: "" }),
        loader.load_rule({ id: "rule4", glob: ["**/*.ts{,x}"], message: "" })
      ],
      exclude_paths: []
    )

    assert_equal ["rule1", "rule2"], config.rules_for_path(Pathname("bar.rb"), rules_filter: []).map(&:first).map(&:id)
    assert_equal ["rule1", "rule3"], config.rules_for_path(Pathname("app/models/user.rb"), rules_filter: []).map(&:first).map(&:id)
    assert_equal ["rule2"], config.rules_for_path(Pathname("app/views/users/index.html.erb"), rules_filter: []).map(&:first).map(&:id)
    assert_equal ["rule4"], config.rules_for_path(Pathname("frontend/src/foo.tsx"), rules_filter: []).map(&:first).map(&:id)
  end

  def test_rules_for_path_glob_empty
    loader = ConfigLoader.new(path: nil, content: nil, stderr: stderr, import_loader: nil)

    config = Config.new(
      rules: [
        loader.load_rule({ id: "rule1", glob: [], message: "" }),
      ],
      exclude_paths: []
    )

    assert_equal ["rule1"], config.rules_for_path(Pathname("bar.rb"), rules_filter: []).map(&:first).map(&:id)
  end

  def test_rules_for_filter
    loader = ConfigLoader.new(path: nil, content: nil, stderr: stderr, import_loader: nil)

    config = Config.new(
      rules: [
        loader.load_rule({ id: "rule1", glob: [], message: "" }),
        loader.load_rule({ id: "rule1.x", glob: [], message: "" }),
        loader.load_rule({ id: "rule2", glob: [], message: "" }),
      ],
      exclude_paths: []
    )

    assert_equal ["rule1", "rule1.x"], config.rules_for_path(Pathname("bar.rb"), rules_filter: ["rule1"]).map(&:first).map(&:id)
  end

  def test_exclude_path
    config = Config.new(rules: [], exclude_paths: ["foo"])

    assert config.exclude_path? Pathname("foo")
    refute config.exclude_path? Pathname("bar")
  end

  def test_exclude_path_by_glob
    config = Config.new(rules: [], exclude_paths: ["foo/**/*.{rb,yml}"])

    assert config.exclude_path? Pathname("foo/a.rb")
    assert config.exclude_path? Pathname("foo/a/b.yml")
    refute config.exclude_path? Pathname("foo/a.py")
    refute config.exclude_path? Pathname("bar/a.rb")
  end

  def test_exclude_path_by_mime_type
    mktmpdir do |dir|
      file = ->(name) do
        (dir / name).tap { |f| f.write("") }
      end

      config = Config.new(rules: [], exclude_paths: [], exclude_binary: true)

      assert config.exclude_path?(Pathname(__dir__) / "fixtures" / "goodcheck-test-rules.tar.gz")
      refute config.exclude_path? file.("a.rb")
      refute config.exclude_path? file.("a.svg")
    end
  end
end
