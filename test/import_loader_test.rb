require "test_helper"

class ImportLoaderTest < Minitest::Test
  include TestHelper

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

  def test_load_file_error
    mktmpdir do |path|
      cache_path = path + "cache"
      cache_path.mkpath

      loader = Goodcheck::ImportLoader.new(cache_path: cache_path, force_download: false, config_path: path + "goodcheck.yml")

      loaded_content = nil

      assert_raises Errno::ENOENT do
        loader.load("rules.yml") do |content|
          loaded_content = content
        end
      end

      # No yield if failed to read file
      assert_nil loaded_content
    end
  end

  SAMPLE_URL = "https://gist.githubusercontent.com/soutaro/6362c89acd7d6771ae6ebfc615be402d/raw/7f04b973c2c8df70783cd7deb955ab95d1375b2d/sample.yml"

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
