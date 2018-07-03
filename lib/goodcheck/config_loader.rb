module Goodcheck
  class ConfigLoader
    include ArrayHelper

    class InvalidPattern < StandardError; end

    Schema = StrongJSON.new do
      let :deprecated_regexp_pattern, object(regexp: string, case_insensitive: boolean?, multiline: boolean?)
      let :deprecated_literal_pattern, object(literal: string, case_insensitive: boolean?)
      let :deprecated_token_pattern, object(token: string, case_insensitive: boolean?)

      let :regexp_pattern, object(regexp: string, case_sensitive: boolean?, multiline: boolean?)
      let :literal_pattern, object(literal: string, case_sensitive: boolean?)
      let :token_pattern, object(token: string, case_sensitive: boolean?)

      let :pattern, enum(regexp_pattern, literal_pattern, token_pattern,
                         deprecated_regexp_pattern, deprecated_literal_pattern, deprecated_token_pattern,
                         string)

      let :encoding, enum(*Encoding.name_list.map {|name| literal(name) })
      let :glob, object(pattern: string, encoding: optional(encoding))

      let :rule, object(
        id: string,
        pattern: enum(array(pattern), pattern),
        message: string,
        justification: optional(enum(array(string), string)),
        glob: optional(enum(array(enum(glob, string)), glob, string)),
        pass: optional(enum(array(string), string)),
        fail: optional(enum(array(string), string))
      )

      let :rules, array(rule)

      let :config, object(rules: rules)
    end

    attr_reader :path
    attr_reader :content
    attr_reader :stderr
    attr_reader :printed_warnings

    def initialize(path:, content:, stderr:)
      @path = path
      @content = content
      @stderr = stderr
      @printed_warnings = Set.new
    end

    def load
      Schema.config.coerce(content)
      rules = content[:rules].map {|hash| load_rule(hash) }
      Config.new(rules: rules)
    end

    def load_rule(hash)
      id = hash[:id]
      patterns = retrieve_patterns(hash)
      justifications = array(hash[:justification])
      globs = load_globs(array(hash[:glob]))
      message = hash[:message].chomp
      passes = array(hash[:pass])
      fails = array(hash[:fail])

      Rule.new(id: id, patterns: patterns, justifications: justifications, globs: globs, message: message, passes: passes, fails: fails)
    end

    def all_patterns_literal?(patterns)
      patterns.all? { |pattern| pattern.class == String || pattern[:literal] }
    end

    def combine_literal_patterns(patterns)
      literals = patterns.map { |pat| pat.class == String ? pat : pat[:literal].to_s }
      Pattern.regexp('(' + literals.join('|') + ')', case_sensitive: true, multiline: nil)
    end

    def retrieve_patterns(hash)
      pat_array = array(hash[:pattern])
      if all_patterns_literal?(pat_array)
        [combine_literal_patterns(pat_array)]
      else
        pat_array.map { |pat| load_pattern(pat) }
      end
    end

    def load_globs(globs)
      globs.map do |glob|
        case glob
        when String
          Glob.new(pattern: glob, encoding: nil)
        when Hash
          Glob.new(pattern: glob[:pattern], encoding: glob[:encoding])
        end
      end
    end

    def load_pattern(pattern)
      case pattern
      when String
        Pattern.literal(pattern, case_sensitive: true)
      when Hash
        case
        when pattern[:literal]
          cs = case_sensitive?(pattern)
          literal = pattern[:literal]
          Pattern.literal(literal, case_sensitive: cs)
        when pattern[:regexp]
          regexp = pattern[:regexp]
          cs = case_sensitive?(pattern)
          multiline = pattern[:multiline]
          Pattern.regexp(regexp, case_sensitive: cs, multiline: multiline)
        when pattern[:token]
          tok = pattern[:token]
          cs = case_sensitive?(pattern)
          Pattern.token(tok, case_sensitive: cs)
        end
      end
    end

    def case_sensitive?(pattern)
      case
      when pattern.key?(:case_sensitive)
        pattern[:case_sensitive]
      when pattern.key?(:case_insensitive)
        print_warning_once "👻 `case_insensitive` option is deprecated. Use `case_sensitive` option instead."
        !pattern[:case_insensitive]
      else
        true
      end
    end

    def print_warning_once(message)
      unless printed_warnings.include?(message)
        stderr.puts "[Warning] " + message
        printed_warnings << message
      end
    end
  end
end
