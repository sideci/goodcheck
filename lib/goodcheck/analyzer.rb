module Goodcheck
  class Analyzer
    attr_reader :rule
    attr_reader :buffer

    def initialize(rule:, buffer:)
      @rule = rule
      @buffer = buffer
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
              range = (scanner.pos - text.bytesize)..scanner.pos
              unless issues.any? { |issue| issue.range == range }
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
