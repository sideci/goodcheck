module Goodcheck
  module Commands
    class Check
      DEFAULT_EXCLUSIONS = [".git", ".svn", ".hg"].freeze

      attr_reader :config_path
      attr_reader :rules
      attr_reader :targets
      attr_reader :reporter
      attr_reader :stderr
      attr_reader :force_download
      attr_reader :home_path

      include ConfigLoading
      include HomePath

      def initialize(config_path:, rules:, targets:, reporter:, stderr:, home_path:, force_download:)
        @config_path = config_path
        @rules = rules
        @targets = targets
        @reporter = reporter
        @stderr = stderr
        @force_download = force_download
        @home_path = home_path
      end

      def run
        handle_config_errors(stderr) do
          issue_reported = false

          reporter.analysis do
            load_config!(force_download: force_download, cache_path: cache_dir_path)
            each_check do |buffer, rule, trigger|
              reported_issues = Set[]

              reporter.rule(rule) do
                analyzer = Analyzer.new(rule: rule, buffer: buffer, trigger: trigger)
                analyzer.scan do |issue|
                  next if issue.location && buffer.line_disabled?(issue.location.start_line)
                  if reported_issues.add?(issue)
                    issue_reported = true
                    reporter.issue(issue)
                  end
                end
              end
            end
          end

          issue_reported ? 2 : 0
        end
      end

      def each_check
        targets.each do |target|
          Goodcheck.logger.info "Checking target: #{target}"
          Goodcheck.logger.tagged target.to_s do
            each_file target, immediate: true do |path|
              Goodcheck.logger.debug "Checking file: #{path}"
              Goodcheck.logger.tagged path.to_s do
                reporter.file(path) do
                  buffers = {}

                  config.rules_for_path(path, rules_filter: rules) do |rule, glob, trigger|
                    Goodcheck.logger.debug "Checking rule: #{rule.id}"
                    begin
                      encoding = glob&.encoding || Encoding.default_external.name

                      if buffers[encoding]
                        buffer = buffers[encoding]
                      else
                        content = path.read(encoding: encoding).encode(Encoding.default_internal || Encoding::UTF_8)
                        buffer = Buffer.new(path: path, content: content)
                        buffers[encoding] = buffer
                      end

                      yield buffer, rule, trigger
                    rescue ArgumentError => exn
                      stderr.puts "#{path}: #{exn.inspect}"
                    end
                  end
                end
              end
            end
          end
        end
      end

      def each_file(path, immediate: false, &block)
        case
        when path.symlink?
          # noop
        when path.directory?
          case
          when DEFAULT_EXCLUSIONS.include?(path.basename.to_s)
            # noop
          when immediate || !excluded?(path)
            path.children.each do |child|
              each_file(child, &block)
            end
          end
        when path.file?
          case
          when path == config_path
            # Skip the config file unless explicitly given by command line
            yield path if immediate
          when excluded?(path)
            # Skip excluded files unless explicitly given by command line
            yield path if immediate
          else
            yield path
          end
        end
      end

      def excluded?(path)
        config.exclude_paths.any? {|pattern| path.fnmatch?(pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end
    end
  end
end
