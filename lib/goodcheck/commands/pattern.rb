module Goodcheck
  module Commands
    class Pattern
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :config_path
      attr_reader :ids
      attr_reader :home_path

      include ConfigLoading
      include HomePath
      include ExitStatus

      def initialize(stdout:, stderr:, path:, ids:, home_path:)
        @stdout = stdout
        @stderr = stderr
        @config_path = path
        @ids = ids
        @home_path = home_path
      end

      def run
        handle_config_errors stderr do
          load_config!(cache_path: cache_dir_path, force_download: true)

          config.rules.each do |rule|
            if ids.empty? || ids.any? {|pat| pat == rule.id || rule.id.start_with?("#{pat}.") }
              stdout.puts "#{rule.id}:"
              rule.triggers.each do |trigger|
                trigger.patterns.each do |pattern|
                  stdout.puts "  - #{pattern.regexp.inspect}"
                end
              end
            end
          end
        end

        EXIT_SUCCESS
      end
    end
  end
end
