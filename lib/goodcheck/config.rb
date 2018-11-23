module Goodcheck
  class Config
    attr_reader :rules

    def initialize(rules:)
      @rules = rules
    end

    def rules_for_path(path, rules_filter:, &block)
      if block_given?
        rules.map do |rule|
          if rules_filter.empty? || rules_filter.any? { |filter| /\A#{Regexp.escape(filter)}\.?/ =~ rule.id }
            if rule.globs.empty?
              [rule, nil]
            else
              glob = rule.globs.find { |glob| path.fnmatch?(glob.pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
              if glob
                [rule, glob]
              end
            end
          end
        end.compact.each(&block)
      else
        enum_for(:rules_for_path, path, rules_filter: rules_filter)
      end
    end
  end
end
