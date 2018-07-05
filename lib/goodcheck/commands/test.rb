module Goodcheck
  module Commands
    class Test
      include ConfigLoading

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :config_path

      def initialize(stdout:, stderr:, config_path:)
        @stdout = stdout
        @stderr = stderr
        @config_path = config_path
      end

      def run
        load_config!

        validate_rule_uniqueness or return 1
        validate_rules or return 1

        0
      end

      def validate_rule_uniqueness
        stdout.puts "Validating rule id uniqueness..."

        duplicated_ids = []

        config.rules.group_by(&:id).each do |id, rules|
          if rules.size > 1
            duplicated_ids << id
          end
        end

        if duplicated_ids.empty?
          stdout.puts "  OK!👍"
          true
        else
          stdout.puts(Rainbow("  Found #{duplicated_ids.size} duplications.😞").red)
          duplicated_ids.each do |id|
            stdout.puts "    #{id}"
          end
          false
        end
      end

      def validate_rules
        test_pass = true

        config.rules.each do |rule|
          if !rule.passes.empty? || !rule.fails.empty?
            stdout.puts "Testing rule #{rule.id}..."

            pass_errors = rule.passes.each.with_index.select do |pass, index|
              rule_matches_example?(rule, pass)
            end

            fail_errors = rule.fails.each.with_index.reject do |fail, index|
              rule_matches_example?(rule, fail)
            end

            unless pass_errors.empty?
              test_pass = false

              pass_errors.each do |_, index|
                stdout.puts "  #{(index+1).ordinalize} pass example matched.😱"
              end
            end

            unless fail_errors.empty?
              test_pass = false

              fail_errors.each do |_, index|
                stdout.puts "  #{(index+1).ordinalize} fail example didn't match.😱"
              end
            end

            if pass_errors.empty? && fail_errors.empty?
              stdout.puts "  OK!🎉"
            end
          end
        end

        test_pass
      end

      def rule_matches_example?(rule, example)
        buffer = Buffer.new(path: Pathname("-"), content: example)
        analyzer = Analyzer.new(rule: rule, buffer: buffer, rules: config.rules)
        analyzer.scan.count > 0
      end
    end
  end
end
