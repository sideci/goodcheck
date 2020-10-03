require "optparse"

module Goodcheck
  class CLI
    include ExitStatus

    attr_reader :stdout
    attr_reader :stderr

    def initialize(stdout:, stderr:)
      @stdout = stdout
      @stderr = stderr
    end

    COMMANDS = {
      init: "Generate a sample configuration file",
      check: "Run check with a configuration",
      test: "Test your configuration",
      pattern: "Print regexp for rules",
      version: "Print version",
      help: "Show help and quit"
    }.freeze

    DEFAULT_CONFIG_FILE = Pathname("goodcheck.yml").freeze

    def run(args)
      command = args.shift&.to_sym

      if COMMANDS.key?(command)
        __send__(command, args)
      elsif command == :"--version"
        version(args)
      else
        if command
          stderr.puts "invalid command: #{command}"
          stderr.puts ""
        end
        help(args)
        EXIT_ERROR
      end
    rescue OptionParser::ParseError => exn
      stderr.puts exn
      EXIT_ERROR
    rescue => exn
      stderr.puts exn.inspect
      exn.backtrace.each do |bt|
        stderr.puts "  #{bt}"
      end
      EXIT_ERROR
    end

    def home_path
      if (path = ENV["GOODCHECK_HOME"])
        Pathname(path)
      else
        Pathname(Dir.home) + ".goodcheck"
      end
    end

    def check(args)
      config_path = DEFAULT_CONFIG_FILE
      targets = []
      rules = []
      formats = [:text, :json]
      format = :text
      loglevel = Logger::ERROR
      force_download = false

      OptionParser.new("Usage: goodcheck check [options] paths...") do |opts|
        config_option(opts) { |config| config_path = config }
        verbose_option(opts) { |level| loglevel = level }
        debug_option(opts) { |level| loglevel = level }
        force_download_option(opts) { force_download = true }
        common_options(opts)

        opts.on("-R RULE", "--rule=RULE", "Only rule(s) to check") do |rule|
          rules << rule
        end

        opts.on("--format=<#{formats.join('|')}>", formats, "Output format [default: '#{format}']") do |f|
          format = f
        end
      end.parse!(args)

      Goodcheck.logger.level = loglevel

      if args.empty?
        targets << Pathname(".")
      else
        args.each {|arg| targets << Pathname(arg) }
      end

      reporter = case format
                 when :text
                   Reporters::Text.new(stdout: stdout)
                 when :json
                   Reporters::JSON.new(stdout: stdout, stderr: stderr)
                 else
                   raise ArgumentError, format.inspect
                 end

      Goodcheck.logger.info "Configuration = #{config_path}"
      Goodcheck.logger.info "Rules = [#{rules.join(", ")}]"
      Goodcheck.logger.info "Format = #{format}"
      Goodcheck.logger.info "Targets = [#{targets.join(", ")}]"
      Goodcheck.logger.info "Force download = #{force_download}"
      Goodcheck.logger.info "Home path = #{home_path}"

      Commands::Check.new(reporter: reporter, config_path: config_path, rules: rules, targets: targets, stderr: stderr, force_download: force_download, home_path: home_path).run
    end

    def test(args)
      config_path = DEFAULT_CONFIG_FILE
      loglevel = ::Logger::ERROR
      force_download = false

      OptionParser.new("Usage: goodcheck test [options]") do |opts|
        config_option(opts) { |config| config_path = config }
        verbose_option(opts) { |level| loglevel = level }
        debug_option(opts) { |level| loglevel = level }
        force_download_option(opts) { force_download = true }
        common_options(opts)
      end.parse!(args)

      Goodcheck.logger.level = loglevel

      Goodcheck.logger.info "Configuration = #{config_path}"
      Goodcheck.logger.info "Force download = #{force_download}"
      Goodcheck.logger.info "Home path = #{home_path}"

      Commands::Test.new(stdout: stdout, stderr: stderr, config_path: config_path, force_download: force_download, home_path: home_path).run
    end

    def init(args)
      config_path = DEFAULT_CONFIG_FILE
      force = false

      OptionParser.new("Usage: goodcheck init [options]") do |opts|
        config_option(opts) { |config| config_path = config }
        common_options(opts)

        opts.on("--force", "Overwrite an existing file") do
          force = true
        end
      end.parse!(args)

      Commands::Init.new(stdout: stdout, stderr: stderr, path: config_path, force: force).run
    end

    def version(_args = nil)
      stdout.puts "goodcheck #{VERSION}"
      EXIT_SUCCESS
    end

    def help(args)
      stdout.puts "Usage: goodcheck <command> [options] [args...]"
      stdout.puts ""
      stdout.puts "Commands:"
      COMMANDS.each do |c, msg|
        stdout.puts "  goodcheck #{c}\t#{msg}"
      end
      EXIT_SUCCESS
    end

    def pattern(args)
      config_path = DEFAULT_CONFIG_FILE

      OptionParser.new do |opts|
        opts.banner = "Usage: goodcheck pattern [options] ids..."
        config_option(opts) { |config| config_path = config }
        common_options(opts)
      end.parse!(args)

      Commands::Pattern.new(stdout: stdout, stderr: stderr, path: config_path, ids: Set.new(args), home_path: home_path).run
    end

    def config_option(opts)
      opts.on("-c CONFIG", "--config=CONFIG", "Configuration file path [default: '#{DEFAULT_CONFIG_FILE}']") do |config|
        yield Pathname(config)
      end
    end

    def verbose_option(opts)
      opts.on("-v", "--verbose", "Set log level to verbose") { yield ::Logger::INFO }
    end

    def debug_option(opts)
      opts.on("-d", "--debug", "Set log level to debug") { yield ::Logger::DEBUG }
    end

    def force_download_option(opts, &block)
      opts.on("--force", "Download importing files always", &block)
    end

    def common_options(opts)
      opts.on_tail("--version", COMMANDS.fetch(:version)) do
        version
        exit EXIT_SUCCESS
      end
      opts.on_tail("-h", "--help", COMMANDS.fetch(:help)) do
        stdout.puts opts.help
        exit EXIT_SUCCESS
      end
    end
  end
end
