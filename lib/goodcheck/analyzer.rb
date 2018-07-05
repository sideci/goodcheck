module Goodcheck
  class Analyzer
    attr_reader :rule
    attr_reader :buffer
    attr_reader :rules

    def initialize(rule:, buffer:, rules:)
      @rule = rule
      @buffer = buffer
      @rules = rules
    end

    # Return all rules associated with this match.
    def affected_rules(rule, matched_text)
      @rules.select { |rule| rule.patterns.find { |pat| pat.regexp.match?(matched_text) } }
    end

    def scan(&block)
      if block_given?
        issues = []

        rule.patterns.each do |pattern|
          scanner = StringScanner.new(buffer.content)

          break_head = pattern.regexp.source.start_with?("\\b")
          after_break = true

          until scanner.eos?
            case
            when scanner.scan(pattern.regexp)
              next if break_head && !after_break

              text = scanner.matched
              affected_rules = affected_rules(rule, text)
              range = (scanner.pos - text.bytesize) .. scanner.pos
              affected_rules.each do |rule|
                issues << Issue.new(buffer: buffer, range: range, rule: rule, text: text)
              end
            when scanner.scan(/.\b/m)
              after_break = true
            else
              scanner.scan(/./m)
              after_break = false
            end
          end
        end

        issues.each(&block)
      else
        enum_for(:scan, &block)
      end
    end
  end
end
