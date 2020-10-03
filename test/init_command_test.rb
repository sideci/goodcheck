require "test_helper"

class InitCommandTest < Minitest::Test
  include Outputs

  Init = Goodcheck::Commands::Init

  def test_init_success
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        init = Init.new(stdout: stdout, stderr: stderr, path: Pathname("goodcheck.yml"), force: false)

        assert_equal 0, init.run

        assert_match %r(Wrote goodcheck\.yml), stdout.string
        assert_operator Pathname("goodcheck.yml"), :file?
        YAML.load(Pathname("goodcheck.yml").read)
      end
    end
  end

  def test_no_force
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        builder.config content: "rules: []"

        init = Init.new(stdout: stdout, stderr: stderr, path: Pathname("goodcheck.yml"), force: false)

        assert_equal 1, init.run
        assert_match %r(goodcheck\.yml already exists\.), stderr.string

        assert_equal({ "rules" => [] }, YAML.load(Pathname("goodcheck.yml").read))
      end
    end
  end

  def test_force
    TestCaseBuilder.tmpdir do |builder|
      builder.cd do
        builder.config content: "rules: []"

        init = Init.new(stdout: stdout, stderr: stderr, path: Pathname("goodcheck.yml"), force: true)

        assert_equal 0, init.run
        assert_match %r(Wrote goodcheck\.yml), stdout.string
        refute_equal({ "rules" => [] }, YAML.load(Pathname("goodcheck.yml").read))
      end
    end
  end
end
