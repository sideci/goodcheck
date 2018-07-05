module Goodcheck
  class Config
    attr_reader :rules

    def initialize(rules:)
      @rules = rules
    end

    def build_global_regexp(rules_filter:)
      if rules_filter.empty?
        Regexp.union(rules.map(&:patterns).compact.flatten.map(&:regexp))
      else
        filtered_rules = rules.select do |rule|
          rules_filter.any? { |filter| /\A#{Regexp.escape(filter)}\.?/ =~ rule.id }
        end
        Regexp.union(filtered_rules.map(&:patterns).compact.flatten.map(&:regexp))
      end
    end

    def rules_for_path(path, rules_filter:, &block)
      if block_given?
        # if rules_filter.empty? || rules_filter.any? { |filter| /\A#{Regexp.escape(filter)}\.?/ =~ rule.id }
        all_globs = rules.map(&:globs).flatten
        all_globs = nil if all_globs.empty?
        global_regexp = build_global_regexp(rules_filter: rules_filter)
        ### Create an effective rule with global_regexp as its pattern
        eff_rule = Rule.new(id: 'effective_rule',
                            patterns: [Pattern.regexp(global_regexp, case_sensitive: false, multiline: false)],
                            message: 'effective rule',
                            justifications: '',
                            globs: all_globs,
                            fails: nil,
                            passes: nil)
        if all_globs
          glob = eff_rule.globs.find { |gl| path.fnmatch?(gl.pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
        end
        if glob
          [[eff_rule, glob]].compact.each(&block)
        else
          [[eff_rule, nil]].compact.each(&block)
        end
      else
        enum_for(:rules_for_path, path, rules_filter: rules_filter)
      end
    end
  end
end
