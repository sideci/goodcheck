module Goodcheck
  module Commands
    class Test
      include ConfigLoading
      include HomePath
      include ExitStatus

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

          if config.rules.empty?
            stdout.puts "No rules."
            return EXIT_SUCCESS
          end

          validate_rule_uniqueness or return EXIT_TEST_FAILED
          validate_rules or return EXIT_TEST_FAILED

          EXIT_SUCCESS
        end
      end

      def validate_rule_uniqueness
        stdout.puts "Validating rule ID uniqueness..."

        duplicated_ids = []

        config.rules.group_by(&:id).each do |id, rules|
          if rules.size > 1
            duplicated_ids << id
          end
        end

        if duplicated_ids.empty?
          stdout.puts Rainbow("  OK! 👍").green
          true
        else
          count = duplicated_ids.size
          duplication = count == 1 ? 'duplication' : 'duplications'
          stdout.puts "  Found #{Rainbow(count).bold} #{duplication}. 😱"
          duplicated_ids.each do |id|
            stdout.puts "    - #{Rainbow(id).background(:red)}"
          end
          false
        end
      end

      def validate_rules
        success_count = 0
        failed_rule_ids = Set[]

        config.rules.each do |rule|
          stdout.puts "Testing rule #{Rainbow(rule.id).cyan}..."

          rule_ok = true

          if rule.triggers.any? {|trigger| !trigger.passes.empty? || !trigger.fails.empty?}
            rule.triggers.each.with_index do |trigger, index|
              if !trigger.passes.empty? || !trigger.fails.empty?
                if trigger.by_pattern?
                  stdout.puts "  Testing pattern..."
                else
                  stdout.puts "  #{index + 1}. Testing trigger..."
                end

                pass_errors = trigger.passes.each.with_index.select do |pass, _|
                  rule_matches_example?(rule, trigger, pass)
                end

                fail_errors = trigger.fails.each.with_index.reject do |fail, _|
                  rule_matches_example?(rule, trigger, fail)
                end

                unless pass_errors.empty?
                  rule_ok = false

                  pass_errors.each do |_, index|
                    stdout.puts "    #{index + 1}. #{Rainbow('pass').green} example matched. 😱"
                    failed_rule_ids << rule.id
                  end
                end

                unless fail_errors.empty?
                  rule_ok = false

                  fail_errors.each do |_, index|
                    stdout.puts "    #{index + 1}. #{Rainbow('fail').red} example didn’t match. 😱"
                    failed_rule_ids << rule.id
                  end
                end
              end
            end

            if rule.triggers.any?(&:skips_fail_examples?)
              stdout.puts "    The rule contains a `pattern` with `glob`, which is not supported by the test command. 🚨"
              stdout.puts "    Skips testing `fail` examples."
            end
          end

          if rule.severity && !config.severity_allowed?(rule.severity)
            allowed_severities = config.allowed_severities.map { |s| %("#{s}") }.join(', ')
            stdout.puts Rainbow("  \"#{rule.severity}\" severity isn’t allowed. Must be one of #{allowed_severities}. 😱").red
            rule_ok = false
            failed_rule_ids << rule.id
          end

          if !rule.severity && config.severity_required?
            stdout.puts Rainbow("  Severity is required. 😱").red
            rule_ok = false
            failed_rule_ids << rule.id
          end

          if rule_ok
            stdout.puts Rainbow("  OK! 👍").green
            success_count += 1
          end
        end

        unless failed_rule_ids.empty?
          stdout.puts ""
          stdout.puts "Failed rules:"
          failed_rule_ids.each do |rule_id|
            stdout.puts "  - #{Rainbow(rule_id).background(:red)}"
          end
        end

        total = success_count + failed_rule_ids.size
        stdout.puts ""
        stdout.puts "#{Rainbow(total).bold} #{total == 1 ? 'rule' : 'rules'} tested: " \
                    "#{Rainbow(success_count.to_s + ' successful').green.bold}, #{Rainbow(failed_rule_ids.size.to_s + ' failed').red.bold}"

        failed_rule_ids.empty?
      end

      def rule_matches_example?(rule, trigger, example)
        buffer = Buffer.new(path: Pathname("-"), content: example)
        analyzer = Analyzer.new(rule: rule, buffer: buffer, trigger: trigger)
        analyzer.scan.count > 0
      end
    end
  end
end
