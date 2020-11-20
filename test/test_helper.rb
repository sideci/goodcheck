require "simplecov"
SimpleCov.start

require "goodcheck"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "test_case_builder"
require "open3"
require "securerandom"
require "tmpdir"

module Assertions
  def assert_pattern(object, regexp: nil, source: nil)
    assert object.is_a?(Goodcheck::Pattern::Token) || object.is_a?(Goodcheck::Pattern::Literal) || object.is_a?(Goodcheck::Pattern::Regexp)
    assert_equal source, object.source if source
    assert_equal regexp, object.regexp if regexp
  end
end

module Outputs
  def stderr
    @stderr ||= StringIO.new
  end

  def stdout
    @stdout ||= StringIO.new
  end
end

Rainbow.enabled = false

module TestHelper
  def mktmpdir
    Dir.mktmpdir do |dir|
      yield Pathname(dir)
    end
  end
end
