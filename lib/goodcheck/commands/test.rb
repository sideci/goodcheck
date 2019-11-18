module Goodcheck
  module Commands
    class Test
      include ConfigLoading
      include HomePath

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :config_path
      attr_reader :home_path
      attr_reader :force_download

      def initialize(stdout:, stderr:, config_path:, force_download:, home_path:)
        @stdout = stdout
        @stderr = stderr
        @config_path = config_path
        @force_download = force_download
        @home_path = home_path
      end

      def run
        handle_config_errors stderr do
          load_config!(cache_path: cache_dir_path, force_download: force_download)

          validate_rule_uniqueness or return 1
          validate_rules or return 1

          0
        end
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
          count = duplicated_ids.size
          stdout.puts(Rainbow("  Found #{count} #{'duplication'.pluralize(count)}.😞").red)
          duplicated_ids.each do |id|
            stdout.puts "    #{id}"
          end
          false
        end
      end

      def validate_rules
        test_pass = true

        config.rules.each do |rule|
          if rule.triggers.any? {|trigger| !trigger.passes.empty? || !trigger.fails.empty?}
            stdout.puts "Testing rule #{rule.id}..."

            rule_ok = true

            rule.triggers.each.with_index do |trigger, index|
              if !trigger.passes.empty? || !trigger.fails.empty?
                if trigger.by_pattern?
                  stdout.puts "  Testing pattern..."
                else
                  stdout.puts "  Testing #{(index+1).ordinalize} trigger..."
                end

                pass_errors = trigger.passes.each.with_index.select do |pass, _|
                  rule_matches_example?(rule, trigger, pass)
                end

                fail_errors = trigger.fails.each.with_index.reject do |fail, _|
                  rule_matches_example?(rule, trigger, fail)
                end

                unless pass_errors.empty?
                  test_pass = false
                  rule_ok = false

                  pass_errors.each do |_, index|
                    stdout.puts "    #{(index+1).ordinalize} pass example matched.😱"
                  end
                end

                unless fail_errors.empty?
                  test_pass = false
                  rule_ok = false

                  fail_errors.each do |_, index|
                    stdout.puts "    #{(index+1).ordinalize} fail example didn't match.😱"
                  end
                end
              end
            end

            if rule.triggers.any?(&:skips_fail_examples?)
              stdout.puts "  🚨 The rule contains a `pattern` with `glob`, which is not supported by the test command."
              stdout.puts "    Skips testing `fail` examples."
            end

            if rule_ok
              stdout.puts "  OK!🎉"
            end
          end
        end

        test_pass
      end

      def rule_matches_example?(rule, trigger, example)
        buffer = Buffer.new(path: Pathname("-"), content: example)
        analyzer = Analyzer.new(rule: rule, buffer: buffer, trigger: trigger)
        analyzer.scan.count > 0
      end
    end
  end
end
