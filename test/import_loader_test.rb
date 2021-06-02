require "test_helper"

class ImportLoaderTest < Minitest::Test
  include TestHelper

  def test_load_unexpected_schema
    loader = Goodcheck::ImportLoader.new(cache_path: nil, force_download: false, config_path: nil)

    error = assert_raises Goodcheck::ImportLoader::UnexpectedSchemaError do
      loader.load("mailto:foo@example.com")
    end
    assert_equal "Unexpected URI schema: mailto", error.message
    assert_equal URI("mailto:foo@example.com"), error.uri
  end

  def test_load_file
    mktmpdir do |path|
      cache_path = path + "cache"
      cache_path.mkpath

      rules_path = path + "rules.yml"
      rule_content = <<EOF
- id: foo
  pattern: FOO
  message: Message
EOF

      rules_path.write rule_content

      loader = Goodcheck::ImportLoader.new(cache_path: cache_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil
      loader.load("rules.yml") do |content|
        loaded_content = content
      end

      assert_equal rule_content, loaded_content
    end
  end

  def test_load_file_via_glob
    mktmpdir do |path|
      cache_path = path + "cache"
      cache_path.mkpath

      rule_content_1 = <<EOF
- id: foo
  pattern: FOO
  message: Message
EOF
      (path + "rules.yml").write rule_content_1

      rule_content_2 = <<EOF
- id: bar
  pattern: BAR
  message: Message
EOF
      (path + ".rules").mkpath
      (path + ".rules" + "bar.yml").write rule_content_2

      loader = Goodcheck::ImportLoader.new(cache_path: cache_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = []
      loader.load("**/*.yml") do |content|
        loaded_content << content
      end

      assert_equal [rule_content_2, rule_content_1], loaded_content
    end
  end

  def test_load_file_tar_gz
    mktmpdir do |path|
      cache_path = path + "cache"
      cache_path.mkpath

      FileUtils.copy_file File.join(__dir__, "fixtures", "goodcheck-test-rules.tar.gz"), path.join("rules.tar.gz")

      loader = Goodcheck::ImportLoader.new(cache_path: cache_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = []
      loader.load("rules.tar.gz") do |content|
        loaded_content << content
      end

      assert_equal 2, loaded_content.size
      assert_match "- id: rule.a", loaded_content[0]
      assert_match "- id: rule.b", loaded_content[1]
    end
  end

  def test_load_file_error
    mktmpdir do |path|
      cache_path = path + "cache"
      cache_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil

      error = assert_raises Goodcheck::ImportLoader::FileNotFound do
        loader.load("rules.yml") do |content|
          loaded_content = content
        end
      end
      assert_equal "No such a file: rules.yml", error.message
      assert_equal "rules.yml", error.path

      # No yield if failed to read file
      assert_nil loaded_content
    end
  end

  SAMPLE_URL = "https://raw.githubusercontent.com/sider/goodcheck/5a61817bd6f16105bdcef1ccfbac62a2b4edeba8/goodcheck.yml"
  SAMPLE_URL_TAR_GZ = "https://raw.githubusercontent.com/sider/goodcheck/e0affdad8f70912f4ebddb37758adfd19dc11d71/test/fixtures/goodcheck-test-rules.tar.gz"

  def test_load_url
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil
      loader.load(SAMPLE_URL) do |content|
        loaded_content = content
      end

      refute_nil loaded_content

      # Test cache is saved
      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      assert_operator cache_path, :file?
      assert_equal cache_path.read, loaded_content
    end
  end

  def test_load_url_tar_gz
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = []
      loader.load(SAMPLE_URL_TAR_GZ) do |content|
        loaded_content << content
      end

      assert_equal 2, loaded_content.size
      assert_match "- id: rule.a", loaded_content[0]
      assert_match "- id: rule.b", loaded_content[1]

      # Test cache is saved
      cache_path_0 = cache_dir_path + loader.cache_name("#{SAMPLE_URL_TAR_GZ}/rules/a.yml")
      assert cache_path_0.file?
      assert_equal cache_path_0.read, loaded_content[0]

      cache_path_1 = cache_dir_path + loader.cache_name("#{SAMPLE_URL_TAR_GZ}/rules/sub/b.yaml")
      assert cache_path_1.file?
      assert_equal cache_path_1.read, loaded_content[1]
    end
  end

  def test_load_url_download_failure
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil

      assert_raises Errno::ECONNREFUSED do
        loader.load("https://localhost") do |content|
          loaded_content = content
        end
      end

      assert_nil loaded_content

      # Test cache is not saved
      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      refute_operator cache_path, :file?
    end
  end

  def test_load_url_processing_failure
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil

      assert_raises RuntimeError do
        loader.load(SAMPLE_URL) do |content|
          loaded_content = content
          raise
        end
      end

      # load yields block
      refute_nil loaded_content

      # Test cache is not saved
      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      refute_operator cache_path, :file?
    end
  end

  def test_load_url_cache_load
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, config_path: path + "goodcheck.yml")

      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      cache_path.write "hello world"

      loaded_content = nil
      loader.load(SAMPLE_URL) do |content|
        loaded_content = content
      end

      # load yields block
      assert_equal "hello world", loaded_content
    end
  end

  def test_load_url_cache_expire
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: false, expires_in: 0, config_path: path + "goodcheck.yml")

      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      cache_path.write "hello world"

      loaded_content = nil
      loader.load(SAMPLE_URL) do |content|
        loaded_content = content
      end

      # Downloaded from internet
      refute_equal "hello world", loaded_content
    end
  end

  def test_load_url_cache_force_download
    mktmpdir do |path|
      cache_dir_path = path + "cache"
      cache_dir_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_dir_path, force_download: true, config_path: path + "goodcheck.yml")

      cache_path = cache_dir_path + loader.cache_name(URI.parse(SAMPLE_URL))
      cache_path.write "hello world"

      loaded_content = nil
      loader.load(SAMPLE_URL) do |content|
        loaded_content = content
      end

      # Downloaded from internet
      refute_equal "hello world", loaded_content
    end
  end

  def test_http_get_failed
    loader = Goodcheck::ImportLoader.new(cache_path: nil, force_download: false, config_path: nil)

    error = assert_raises RuntimeError do
      loader.http_get('https://github.com/sider/goodcheck/not_found.txt')
    end
    assert_includes error.message, 'Error: HTTP GET "https://github.com/sider/goodcheck/not_found.txt"'
  end
end
