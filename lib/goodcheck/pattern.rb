module Goodcheck
  class Pattern
    attr_reader :source
    attr_reader :regexp

    def initialize(source:, regexp:)
      @source = source
      @regexp = regexp
    end

    def self.literal(literal, case_sensitive:)
      new(source: literal, regexp: Regexp.compile(Regexp.escape(literal), !case_sensitive))
    end

    def self.regexp(regexp, case_sensitive:, multiline:)
      options = 0
      options |= Regexp::IGNORECASE unless case_sensitive
      options |= Regexp::MULTILINE if multiline

      if regexp.is_a? String
        new(source: regexp, regexp: Regexp.compile(regexp, options))
      else
        new(source: regexp, regexp: Regexp.compile(regexp))
      end
    end

    def self.token(tokens, case_sensitive:)
      new(source: tokens, regexp: compile_tokens(tokens, case_sensitive: case_sensitive))
    end

    def self.compile_tokens(source, case_sensitive:)
      tokens = []
      s = StringScanner.new(source)

      until s.eos?
        case
        when s.scan(/\(|\)|\{|\}|\[|\]|\<|\>/)
          tokens << Regexp.escape(s.matched)
        when s.scan(/\s+/)
          tokens << '\s+'
        when s.scan(/\w+|[\p{Letter}&&\p{^ASCII}]+/)
          tokens << Regexp.escape(s.matched)
        when s.scan(%r{[!"#$%&'=\-^~¥\\|`@*:+;/?.,]+})
          tokens << Regexp.escape(s.matched.rstrip)
        when s.scan(/./)
          tokens << Regexp.escape(s.matched)
        end
      end

      if tokens.first =~ /\A\p{Letter}/
        tokens.first.prepend('\b')
      end

      if tokens.last =~ /\p{Letter}\Z/
        tokens.last << '\b'
      end

      options = Regexp::MULTILINE
      options |= Regexp::IGNORECASE unless case_sensitive

      Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), options)
    end
  end
end
