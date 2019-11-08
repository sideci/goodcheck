module Goodcheck
  class Trigger
    attr_reader :patterns
    attr_reader :globs
    attr_reader :passes
    attr_reader :fails
    attr_reader :negated

    def initialize(patterns:, globs:, passes:, fails:, negated:)
      @patterns = patterns
      @globs = globs
      @passes = passes
      @fails = fails
      @negated = negated
      @by_pattern = false
      @skips_fail_examples = false
    end

    def by_pattern!
      @by_pattern = true
      self
    end

    def by_pattern?
      # True if the trigger is from `pattern` or `not` attribute (compatible mode.)
      @by_pattern
    end

    def skips_fail_examples!(flag = true)
      @skips_fail_examples = flag
      self
    end

    def skips_fail_examples?
      @skips_fail_examples
    end

    def negated?
      @negated
    end

    def fires_for?(path:)
      globs.any? {|glob| glob.test(path) }
    end
  end
end
