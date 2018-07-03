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

      new(source: regexp, regexp: Regexp.compile(regexp, options))
    end

    def self.token(tokens, case_sensitive:)
      new(source: tokens, regexp: compile_tokens(tokens, case_sensitive: case_sensitive))
    end

    def self.extract_tokens(source)
      tokens = []
      s = StringScanner.new(source)
      regexps = [/\(|\)|\{|\}|\[|\]|\<|\>/,
                 /\s+/,
                 /\w+|[\p{Letter}&&\p{^ASCII}]+/,
                 %r{[!"#$%&'=\-^~¥\\|`@*:+;/?.,]+},
                 /./]
      until s.eos?
        regexps.each_with_index do |regexp, idx|
          next unless s.scan(regexp)
          tokens << Regexp.escape(s.matched.rstrip) if idx == 3
          tokens << Regexp.escape(s.matched) unless idx == 3
          break
        end
      end
      tokens
    end

    def self.compile_tokens(source, case_sensitive:)
      tokens = extract_tokens(source)
      tokens.first.prepend('\b') if tokens.first =~ /\A\p{Letter}/
      tokens.last << '\b' if tokens.last =~ /\p{Letter}\Z/
      options = Regexp::MULTILINE
      options |= Regexp::IGNORECASE unless case_sensitive
      Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), options)
    end
  end
end
