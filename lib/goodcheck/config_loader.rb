module Goodcheck
  class ConfigLoader
    include ArrayHelper

    class InvalidPattern < Error; end

    Schema = StrongJSON.new do
      def self.array_or(type)
        a = array(type)
        enum(a, type, detector: -> (value) {
          case value
          when Array
            a
          else
            type
          end
        })
      end

      let :deprecated_regexp_pattern, object(regexp: string, case_insensitive: boolean?, multiline: boolean?)
      let :deprecated_literal_pattern, object(literal: string, case_insensitive: boolean?)
      let :deprecated_token_pattern, object(token: string, case_insensitive: boolean?)

      let :encoding, enum(*Encoding.name_list.map {|name| literal(name) })
      let :glob_obj, object(pattern: string, encoding: optional(encoding),
                            exclude: enum?(string, array(string)))
      let :one_glob, enum(glob_obj,
                          string,
                          detector: -> (value) {
                            case value
                            when Hash
                              glob_obj
                            when String
                              string
                            end
                          })
      let :glob, array_or(one_glob)

      let :var_pattern, any
      let :variable_pattern, array_or(var_pattern)
      let :negated_variable_pattern, object(not: variable_pattern)

      let :where, hash(
        enum(
          variable_pattern,
          negated_variable_pattern,
          literal(true),
          detector: -> (value) {
            case
            when value.is_a?(Hash) && value.key?(:not)
              negated_variable_pattern
            when value == true
              literal(true)
            else
              variable_pattern
            end
          }
        )
      )

      let :regexp_pattern, object(regexp: string, case_sensitive: boolean?, multiline: boolean?, glob: optional(glob))
      let :literal_pattern, object(literal: string, case_sensitive: boolean?, glob: optional(glob))
      let :token_pattern, object(
        token: string,
        case_sensitive: boolean?,
        glob: optional(glob),
        where: optional(where)
      )

      let :pattern, enum(regexp_pattern,
                         literal_pattern,
                         token_pattern,
                         deprecated_regexp_pattern,
                         deprecated_literal_pattern,
                         deprecated_token_pattern,
                         string,
                         detector: -> (value) {
                           case value
                           when Hash
                             case
                             when value.key?(:regexp) && value.key?(:case_insensitive)
                               deprecated_regexp_pattern
                             when value.key?(:regexp)
                               regexp_pattern
                             when value.key?(:literal) && value.key?(:case_insensitive)
                               deprecated_literal_pattern
                             when value.key?(:literal)
                               literal_pattern
                             when value.key?(:token) && value.key?(:case_insensitive)
                               deprecated_token_pattern
                             when value.key?(:token)
                               token_pattern
                             end
                           when String
                             string
                           end
                         })

      let :positive_rule, object(
        id: string,
        pattern: array_or(pattern),
        message: string,
        justification: optional(array_or(string)),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string)),
        severity: optional(string)
      )

      let :negative_rule, object(
        id: string,
        not: object(pattern: array_or(pattern)),
        message: string,
        justification: optional(array_or(string)),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string)),
        severity: optional(string)
      )

      let :nopattern_rule, object(
        id: string,
        message: string,
        justification: optional(array_or(string)),
        glob: glob,
        severity: optional(string)
      )

      let :positive_trigger, object(
        pattern: array_or(pattern),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string))
      )

      let :negative_trigger, object(
        not: object(pattern: array_or(pattern)),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string))
      )

      let :nopattern_trigger, object(
        glob: glob_obj
      )

      let :trigger, enum(
        positive_trigger,
        negative_trigger,
        nopattern_trigger,
        detector: -> (hash) {
          if hash.is_a?(Hash)
            case
            when hash.key?(:pattern)
              positive_trigger
            when hash.key?(:not)
              negative_trigger
            else
              nopattern_trigger
            end
          end
        }
      )

      let :triggered_rule, object(
        id: string,
        message: string,
        justification: optional(array_or(string)),
        trigger: array_or(trigger),
        severity: optional(string)
      )

      let :rule, enum(positive_rule,
                      negative_rule,
                      nopattern_rule,
                      triggered_rule,
                      detector: -> (hash) {
                        if hash.is_a?(Hash)
                          case
                          when hash[:trigger]
                            triggered_rule
                          when hash[:pattern]
                            positive_rule
                          when hash[:not]
                            negative_rule
                          when hash.key?(:glob) && !hash.key?(:pattern) && !hash.key?(:not)
                            nopattern_rule
                          end
                        end
                      })

      let :rules, array(rule)

      let :severity, object(
        allow: optional(array(string)),
        required: boolean?,
      )

      let :config, object(
        rules: optional(rules),
        import: optional(array(string)),
        exclude: optional(array_or(string)),
        exclude_binary: boolean?,
        severity: optional(severity)
      )
    end

    attr_reader :path
    attr_reader :content
    attr_reader :stderr
    attr_reader :printed_warnings
    attr_reader :import_loader

    def initialize(path:, content:, stderr:, import_loader:)
      @path = path
      @content = content
      @stderr = stderr
      @printed_warnings = Set.new
      @import_loader = import_loader
    end

    def load
      Goodcheck.logger.info "Loading configuration: #{path}"
      Schema.config.coerce(content)

      rules = []

      load_rules(rules, array(content[:rules]))

      Array(content[:import]).each do |import|
        load_import rules, import
      end

      Config.new(
        rules: rules,
        exclude_paths: Array(content[:exclude]),
        exclude_binary: content[:exclude_binary]
      )
    end

    def load_rules(rules, array)
      array.each do |hash|
        rules << load_rule(hash)
      rescue RegexpError => exn
        raise InvalidPattern, "Invalid pattern of the `#{hash.fetch(:id)}` rule in `#{path}`: #{exn.message}"
      end
    end

    def load_import(rules, import)
      Goodcheck.logger.info "Importing rules from #{import}"

      import_loader.load(import) do |content, filename|
        json = JSON.parse(JSON.dump(YAML.safe_load(content, filename: filename)), symbolize_names: true)

        Schema.rules.coerce json
        load_rules(rules, json)
      end
    end

    def load_rule(hash)
      Goodcheck.logger.debug "Loading rule: #{hash[:id]}"

      id = hash[:id]
      triggers = retrieve_triggers(hash)
      justifications = array(hash[:justification])
      message = hash[:message].chomp

      Rule.new(id: id, message: message, justifications: justifications, triggers: triggers)
    end

    def retrieve_triggers(hash)
      if hash.key?(:trigger)
        array(hash[:trigger]).map do |trigger|
          retrieve_trigger(trigger)
        end
      else
        globs = load_globs(array(hash[:glob]))
        passes = array(hash[:pass])
        fails = array(hash[:fail])

        if hash.key?(:not) || hash.key?(:pattern)
          if hash.key?(:not)
            negated = true
            patterns = array(hash[:not][:pattern])
          else
            negated = false
            patterns = array(hash[:pattern])
          end

          glob_patterns, noglob_patterns = patterns.partition {|pat|
            pat.is_a?(Hash) && pat.key?(:glob)
          }

          skip_fails = !fails.empty? && !glob_patterns.empty?

          glob_patterns.map do |pat|
            Trigger.new(
              patterns: [load_pattern(pat)],
              globs: load_globs(array(pat[:glob])),
              passes: passes,
              fails: [],
              negated: negated
            ).by_pattern!.skips_fail_examples!(skip_fails)
          end.push(
            Trigger.new(
              patterns: noglob_patterns.map {|pat| load_pattern(pat) },
              globs: globs,
              passes: passes,
              fails: glob_patterns.empty? ? fails : [],
              negated: negated
            ).by_pattern!.skips_fail_examples!(skip_fails)
          )
        else
          [Trigger.new(patterns: [],
                       globs: globs,
                       passes: passes,
                       fails: fails,
                       negated: false).by_pattern!]
        end
      end
    end

    def retrieve_trigger(hash)
      patterns, negated = retrieve_patterns(hash)
      globs = load_globs(array(hash[:glob]))
      passes = array(hash[:pass])
      fails = array(hash[:fail])

      Trigger.new(patterns: patterns,
                  globs: globs,
                  passes: passes,
                  fails: fails,
                  negated: negated)
    end

    def retrieve_patterns(hash)
      if hash.is_a?(Hash) && hash.key?(:not)
        negated = true
        hash = hash[:not]
      else
        negated = false
      end

      if hash.key?(:pattern)
        [array(hash[:pattern]).map {|pat| load_pattern(pat) }, negated]
      else
        [[], false]
      end
    end

    def load_globs(globs)
      globs.map do |glob|
        case glob
        when String
          Glob.new(pattern: glob, encoding: nil, exclude: nil)
        when Hash
          Glob.new(pattern: glob[:pattern], encoding: glob[:encoding], exclude: glob[:exclude])
        end
      end
    end

    def load_pattern(pattern)
      case pattern
      when String
        case (pat = load_string_pattern(pattern))
        when String
          Pattern::Literal.new(source: pat, case_sensitive: true)
        when ::Regexp
          Pattern::Regexp.new(source: pattern,
                              regexp: pat,
                              multiline: pat.options & ::Regexp::MULTILINE == ::Regexp::MULTILINE,
                              case_sensitive: !pat.casefold?)
        end
      when Hash
        if pattern[:glob]
          print_warning_once "🌏 Pattern with glob is deprecated: globs are ignored at all."
        end

        case
        when pattern[:literal]
          cs = case_sensitive?(pattern)
          literal = pattern[:literal]
          Pattern::Literal.new(source: literal, case_sensitive: cs)
        when pattern[:regexp]
          regexp = pattern[:regexp]
          cs = case_sensitive?(pattern)
          multiline = pattern[:multiline]
          Pattern::Regexp.new(source: regexp, case_sensitive: cs, multiline: multiline)
        when pattern[:token]
          tok = pattern[:token]
          cs = case_sensitive?(pattern)
          Pattern::Token.new(source: tok, variables: load_token_vars(pattern[:where]), case_sensitive: cs)
        end
      end
    end

    def load_string_pattern(string)
      if string =~ /\A\/(.*)\/([im]*)\Z/
        source = $1
        opts = $2
        options = 0
        options |= ::Regexp::IGNORECASE if opts =~ /i/
        options |= ::Regexp::MULTILINE if opts =~ /m/
        ::Regexp.new(source, options)
      else
        string
      end
    end

    def load_token_vars(pattern)
      case pattern
      when Hash
        pattern.each.with_object({}) do |(key, value), hash|
          hash[key.to_sym] = load_var_pattern(value)
        end
      else
        {}
      end
    end

    def load_var_pattern(pattern)
      if pattern.is_a?(Hash) && pattern[:not]
        negated = true
        pattern = pattern[:not]
      else
        negated = false
      end

      pattern = [] if pattern == true

      patterns = array(pattern).map do |pat|
        case pat
        when String
          load_string_pattern(pat)
        else
          pat
        end
      end

      Pattern::Token::VarPattern.new(patterns: patterns, negated: negated)
    end

    def case_sensitive?(pattern)
      return true if pattern.is_a?(String)
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
